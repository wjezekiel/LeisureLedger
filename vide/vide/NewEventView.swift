import SwiftUI

struct NewEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var events: [Event]
    @State private var eventName = ""
    @State private var eventDate = Date()
    @State private var people: [Person] = []
    @State private var newPersonName = ""
    @State private var showingDuplicateNameError = false
    @State private var duplicateNameMessage = ""
    let onEventCreated: (Int) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Name", text: $eventName)
                    DatePicker("Date", selection: $eventDate)
                }
                
                Section("People") {
                    ForEach(people) { person in
                        HStack {
                            Circle()
                                .fill(person.color)
                                .frame(width: 10, height: 10)
                            Text(person.name)
                        }
                    }
                    .onDelete { indexSet in
                        people.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("Add Person", text: $newPersonName)
                        Button("Add") {
                            addPerson()
                        }
                        .disabled(newPersonName.isEmpty)
                    }
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let newEvent = Event(
                            name: eventName,
                            date: eventDate,
                            people: people,
                            items: []
                        )
                        events.append(newEvent)
                        dismiss()
                        onEventCreated(events.count - 1)
                    }
                    .disabled(eventName.isEmpty || people.isEmpty)
                }
            }
            .alert("Duplicate Name", isPresented: $showingDuplicateNameError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(duplicateNameMessage)
            }
        }
    }
    
    private func addPerson() {
        let trimmedName = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if people.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            duplicateNameMessage = "'\(trimmedName)' already exists"
            showingDuplicateNameError = true
            return
        }
        
        let person = Person(name: trimmedName)
        people.append(person)
        newPersonName = ""
    }
} 