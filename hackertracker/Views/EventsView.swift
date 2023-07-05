//
//  EventsView.swift
//
//  Created by Caleb Kinney on 3/27/23.
//

import SwiftUI

struct EventsView: View {
    let events: [Event]
    let conference: Conference?
    let bookmarks: [Int32]
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @AppStorage("showPastEvents") var showPastEvents: Bool = true
    @EnvironmentObject var viewModel: InfoViewModel
    let dfu = DateFormatterUtility.shared

    @State private var eventDay = ""
    @State private var searchText = ""
    @State private var filters: Set<Int> = []
    @State private var showFilters = false
    var body: some View {
        NavigationStack {
            EventScrollView(events: events
                .filters(typeIds: filters, bookmarks: bookmarks)
                .search(text: searchText)
                .eventDayGroup(), bookmarks: bookmarks, dayTag: eventDay, showPastEvents: showPastEvents)
            .navigationTitle(viewModel.conference?.name ?? "Schedule")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Menu {
                            Toggle(isOn: $showLocaltime) {
                                Label("Display Localtime", systemImage: "clock")
                            }
                            .onChange(of: showLocaltime) { value in
                                print("EventsView: Changing to showLocaltime = \(value)")
                                viewModel.showLocaltime = value
                                if showLocaltime {
                                    dfu.update(tz: TimeZone.current)
                                } else {
                                    dfu.update(tz: TimeZone(identifier: conference?.timezone ?? "America/Los_Angeles"))
                                }
                            }
                            Toggle(isOn: $showPastEvents) {
                                Label("Show Past Events", systemImage: "calendar")
                            }
                            .onChange(of: showPastEvents) { value in
                                print("EventsView: Changing to showPastEvents = \(value)")
                                viewModel.showPastEvents = value
                            }
                            .toggleStyle(.automatic)
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Menu {
                            ForEach(events.filters(typeIds: filters, bookmarks: bookmarks).eventDayGroup().sorted {
                                $0.key < $1.key
                            }, id: \.key) { day, _ in
                                Button(dfu.dayMonthDayOfWeekFormatter.string(from: day)) {
                                    eventDay = dfu.dayOfWeekFormatter.string(from: day) // day.formatted(.dateTime.weekday())
                                }
                            }

                        } label: {
                            Image(systemName: "calendar")
                        }

                        Button {
                            showFilters.toggle()
                        } label: {
                            Image(systemName: filters
                                .isEmpty
                                ? "line.3.horizontal.decrease.circle"
                                : "line.3.horizontal.decrease.circle.fill")
                        }
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        }
        .sheet(isPresented: $showFilters) {
            EventFilters(types: events.types(), showFilters: $showFilters, filters: $filters)
        }
        .onChange(of: viewModel.conference) { con in
            print("EventsView.onChange(of: conference) == \(con?.name ?? "not found")")
            self.filters = []
        }
    }
}

struct EventFilters: View {
    let types: [Int: EventType]
    @Binding var showFilters: Bool
    @Binding var filters: Set<Int>

    var body: some View {
        NavigationStack {
            List {
                FilterRow(id: 1337, name: "Bookmarks", color: .primary, filters: $filters)

                Section(header: Text("Event Category")) {
                    ForEach(types.sorted {
                        $0.value.name < $1.value.name
                    }, id: \.key) { id, type in
                        FilterRow(id: id, name: type.name, color: type.swiftuiColor, filters: $filters)
                    }
                }.headerProminence(.increased)
            }
            .listStyle(.plain)
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        filters.removeAll()
                    }
                    Button("Close") {
                        showFilters = false
                    }
                }
            }
        }
    }
}

struct EventScrollView: View {
    let events: [Date: [Event]]
    let bookmarks: [Int32]
    let dayTag: String
    let showPastEvents: Bool
    let dfu = DateFormatterUtility.shared

    var body: some View {
        ScrollViewReader { proxy in
            List(events.sorted {
                $0.key < $1.key
            }, id: \.key) { weekday, events in
                if showPastEvents || weekday >= Date() {
                    EventData(weekday: weekday, events: events, bookmarks: bookmarks, showPastEvents: showPastEvents)
                        .id(dfu.dayOfWeekFormatter.string(from: weekday))
                }
            }
            .listStyle(.plain)
            .onChange(of: dayTag) { changedValue in
                proxy.scrollTo(changedValue, anchor: .top)
            }
        }
    }
}

struct EventData: View {
    let weekday: Date
    let events: [Event]
    let bookmarks: [Int32]
    let showPastEvents: Bool
    let dfu = DateFormatterUtility.shared

    var body: some View {
        Section(header: Text(dfu.longMonthDayFormatter.string(from: weekday))) {
            ForEach(events.eventDateTimeGroup().sorted {
                $0.key < $1.key
            }, id: \.key) { time, timeEvents in
                if showPastEvents || time >= Date() {
                    Section(header: Text(dfu.hourMinuteTimeFormatter.string(from: time))) {
                        ForEach(timeEvents.sorted {
                            $0.beginTimestamp < $1.beginTimestamp
                        }, id: \.id) { event in
                            if showPastEvents || event.beginTimestamp >= Date() {
                                NavigationLink(destination: EventDetailView(eventId: event.id, bookmarks: bookmarks)) {
                                    EventCell(event: event, bookmarks: bookmarks)
                                }
                            }
                        }
                    }
                }
            }
        }
        .headerProminence(.increased)
    }
}

struct FilterRow: View {
    let id: Int
    let name: String
    let color: Color
    @Binding var filters: Set<Int>

    var body: some View {
        HStack {
            if !filters.contains(id) {
                Circle()
                    .strokeBorder(color, lineWidth: 5)
                    .frame(width: 25, height: 25).padding()
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 25, height: 25)
                    .padding()
            }
            Text(name)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if filters.contains(id) {
                filters.remove(id)
            } else {
                filters.insert(id)
            }
        }
    }
}
