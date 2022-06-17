//
//  EventDetailView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/14/22.
//

import SwiftUI

struct EventDetailView: View {
    var event: Event
    @State var bookmarks: [Int]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(event.title).font(.largeTitle)
                HStack {
                    Circle().fill(event.type.swiftuiColor).frame(width: 10, height: 10)
                    Text(event.type.name)
                }
                .rectangleBackground()

                HStack {
                    Image(systemName: "clock")
                    Text(dateSection(date: event.beginTimestamp))
                }
                .rectangleBackground()

                HStack {
                    Image(systemName: "map")
                    Text(event.location.name)
                }
                .rectangleBackground()

                Text(event.description).padding(.top).padding()

                if !event.speakers.isEmpty {
                    Text("Speakers").font(.headline).padding(.top)

                    VStack(alignment: .leading) {
                        ForEach(event.speakers) { speaker in
                            NavigationLink(destination: SpeakerDetailView(id: speaker.id)) {
                                HStack {
                                    Rectangle().fill(Color.yellow).frame(width: 10, height: .infinity)
                                    VStack(alignment: .leading) {
                                        Text(speaker.name).fontWeight(.bold)
                                        Text(speaker.title ?? "Hacker")
                                    }
                                }
                            }
                        }
                    }
                    .rectangleBackground()
                }

                Spacer()
            }
            .navigationTitle(event.title)
        }
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScheduleView().preferredColorScheme(.light)
        }
    }
}
