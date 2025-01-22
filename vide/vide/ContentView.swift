//
//  ContentView.swift
//  vide
//
//  Created by Ezekiel Chow on 1/17/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var events: [Event] = []
    @State private var showingNewEventSheet = false
    @State private var newEventIndex: Int?
    @State private var showingEventDetail = false
    @State private var selectedEventIndex: Int?
    
    // Calculate the height for a single event card
    private let cardHeight: CGFloat = 80
    
    // Calculate dynamic height based on number of events
    private func eventsHeight(_ screenHeight: CGFloat) -> CGFloat {
        let maxHeight = screenHeight * 0.3
        let contentHeight = CGFloat(min(events.count, 3)) * cardHeight
        return min(maxHeight, contentHeight)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? 
            Color(red: 0.05, green: 0.1, blue: 0.2) :
            Color(red: 0.85, green: 0.9, blue: 1.0)
    }
    
    private var cardColor: Color {
        colorScheme == .dark ? 
            Color(red: 0.15, green: 0.17, blue: 0.22) :
            Color(red: 0.97, green: 0.98, blue: 1.0)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                List {
                    if !events.isEmpty {
                        Section("Events") {
                            ScrollView {
                                LazyVStack(spacing: 2) {
                                    ForEach(events.reversed().indices, id: \.self) { index in
                                        NavigationLink {
                                            let originalIndex = events.count - 1 - index
                                            EventDetailView(event: $events[originalIndex])
                                        } label: {
                                            EventRowView(event: events.reversed()[index])
                                                .padding(.vertical, 4)
                                                .padding(.horizontal, 8)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(cardColor)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(height: eventsHeight(UIScreen.main.bounds.height))
                            
                            Button(action: {
                                showingNewEventSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.tint)
                                    Text("Add Event")
                                }
                            }
                            .listRowBackground(cardColor)
                        }
                        .listSectionSpacing(0)
                    } else {
                        ContentUnavailableView {
                            Label("No Events", systemImage: "receipt")
                        } description: {
                            Text("Tap + to create a new bill splitting event")
                        } actions: {
                            Button(action: {
                                showingNewEventSheet = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .sheet(isPresented: $showingNewEventSheet) {
                NewEventView(events: $events) { newIndex in
                    selectedEventIndex = newIndex
                    showingEventDetail = true
                }
            }
            .sheet(isPresented: $showingEventDetail) {
                if let index = selectedEventIndex {
                    EventDetailView(event: $events[index])
                }
            }
        }
    }
}

struct EventRowView: View {
    let event: Event
    
    var peopleNames: String {
        event.people.map { $0.name }.joined(separator: ", ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.name)
                .font(.headline)
                .padding(.top, 4)
            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(peopleNames)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.bottom, 4)
        }
    }
}

#Preview {
    ContentView()
}

