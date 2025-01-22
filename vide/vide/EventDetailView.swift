import SwiftUI
import Foundation

struct EventDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var event: Event
    @State private var showingNewItemSheet = false
    @State private var showingSummary = false
    @State private var showingAddPersonSheet = false
    @State private var newPersonName = ""
    @State private var editingPerson: Person? = nil
    @State private var editingItem: Item? = nil
    @State private var editedName = ""
    @State private var showingDuplicateNameError = false
    @State private var duplicateNameMessage = ""
    
    private var backgroundColor: Color {
        colorScheme == .dark ? 
            Color(red: 0.05, green: 0.1, blue: 0.2) :   // Deep navy blue for dark mode
            Color(red: 0.85, green: 0.9, blue: 1.0)     // Light blue for light mode
    }
    
    private var cardColor: Color {
        colorScheme == .dark ? 
            Color(red: 0.15, green: 0.17, blue: 0.22) : // Slightly lighter navy
            Color(red: 0.93, green: 0.97, blue: 1.0)    // Light sky blue cards
    }
    
    private var accentColor: Color {
        colorScheme == .dark ? 
            Color(red: 0.2, green: 0.23, blue: 0.28) :  // Even lighter navy for emphasis
            Color(red: 0.85, green: 0.92, blue: 0.98)   // Light sky blue accent
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            List {
                if !event.items.isEmpty {
                    Section {
                        Button(action: {
                            showingSummary = true
                        }) {
                            HStack {
                                Text("View Bill Summary")
                                Spacer()
                                Image(systemName: "dollarsign.circle.fill")
                            }
                        }
                        .listRowBackground(accentColor)
                    }
                }
                
                Section("People") {
                    ForEach(event.people) { person in
                        HStack {
                            Circle()
                                .fill(person.color)
                                .frame(width: 10, height: 10)
                            Text(person.name)
                            Spacer()
                            Button(action: {
                                editingPerson = person
                                editedName = person.name
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .listRowBackground(cardColor)
                    }
                    .onDelete { indexSet in
                        // Remove person's items before removing the person
                        let personToRemove = event.people[indexSet.first!]
                        event.items.removeAll { item in
                            item.sharedBy.contains(personToRemove.id)
                        }
                        event.people.remove(atOffsets: indexSet)
                    }
                    
                    Button(action: {
                        showingAddPersonSheet = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Person")
                        }
                    }
                    .listRowBackground(cardColor)
                }
                
                Section("Items") {
                    if event.items.isEmpty {
                        ContentUnavailableView {
                            Label("No Items", systemImage: "cart")
                        } description: {
                            Text("Tap + to add items to split")
                        } actions: {
                            Button(action: {
                                showingNewItemSheet = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.tint)
                            }
                        }
                    } else {
                        ForEach($event.items) { $item in
                            ItemRowView(item: item, people: event.people)
                                .listRowBackground(cardColor)
                                .contextMenu {
                                    Button(action: {
                                        editingItem = item
                                        editedName = item.name
                                    }) {
                                        Label("Edit Item", systemImage: "pencil")
                                    }
                                    
                                    Button(action: {
                                        editingItem = item // This will show sharing sheet
                                    }) {
                                        Label("Edit Sharing", systemImage: "person.2")
                                    }
                                }
                        }
                        .onDelete { indexSet in
                            event.items.remove(atOffsets: indexSet)
                        }
                        
                        Button(action: {
                            showingNewItemSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.tint)
                                Text("Add Item")
                            }
                        }
                        .listRowBackground(cardColor)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(event.name)
        .sheet(isPresented: $showingNewItemSheet) {
            NewItemView(event: $event)
        }
        .sheet(isPresented: $showingSummary) {
            BillSummaryView(event: event)
        }
        .alert("Edit Person", isPresented: .init(
            get: { editingPerson != nil },
            set: { if !$0 { editingPerson = nil } }
        )) {
            TextField("Name", text: $editedName)
            Button("Cancel", role: .cancel) {
                editingPerson = nil
            }
            Button("Save") {
                if let index = event.people.firstIndex(where: { $0.id == editingPerson?.id }) {
                    event.people[index].name = editedName
                }
                editingPerson = nil
            }
        }
        .sheet(isPresented: .init(
            get: { editingItem != nil },
            set: { if !$0 { editingItem = nil } }
        )) {
            if let itemIndex = event.items.firstIndex(where: { $0.id == editingItem?.id }) {
                EditItemView(item: $event.items[itemIndex], people: event.people)
            }
        }
        .alert("Add Person", isPresented: $showingAddPersonSheet) {
            TextField("Name", text: $newPersonName)
            Button("Cancel", role: .cancel) {
                newPersonName = ""
            }
            Button("Add") {
                addPerson()
            }
        } message: {
            Text("Enter the name of the person to add")
        }
        .alert("Duplicate Name", isPresented: $showingDuplicateNameError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(duplicateNameMessage)
        }
    }
    
    private func addPerson() {
        let trimmedName = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Check if name already exists
        if event.people.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            duplicateNameMessage = "'\(trimmedName)' already exists"
            showingDuplicateNameError = true
            return
        }
        
        let person = Person(name: trimmedName)
        event.people.append(person)
        newPersonName = ""
    }
}

struct ItemRowView: View {
    let item: Item
    let people: [Person]
    
    var sharedByNames: String {
        let names = people
            .filter { person in item.sharedBy.contains(person.id) }
            .map { $0.name }
        return names.joined(separator: ", ")
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(item.name)
                    .font(.headline)
                if item.quantity > 1 {
                    Text("×\(item.quantity)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            Text(String(format: "$%.2f", item.price))
                .font(.subheadline)
            if !sharedByNames.isEmpty {
                Text("Shared by: \(sharedByNames)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct NewItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var event: Event
    
    @State private var itemName = ""
    @State private var itemPrice = ""
    @State private var quantity = 1
    @State private var selectedPeople: Set<UUID> = []
    @State private var selectAll = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $itemName)
                    TextField("Price (per item)", text: $itemPrice)
                        .keyboardType(.decimalPad)
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                    
                    if quantity > 1 {
                        HStack {
                            Text("Total Price:")
                            Spacer()
                            if let price = Double(itemPrice) {
                                Text(String(format: "$%.2f", price * Double(quantity)))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Shared By") {
                    if !event.people.isEmpty {
                        Toggle("Select All", isOn: Binding(
                            get: { selectAll },
                            set: { newValue in
                                selectAll = newValue
                                if newValue {
                                    selectedPeople = Set(event.people.map { $0.id })
                                } else {
                                    selectedPeople.removeAll()
                                }
                            }
                        ))
                    }
                    
                    ForEach(event.people) { person in
                        Toggle(person.name, isOn: Binding(
                            get: { selectedPeople.contains(person.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedPeople.insert(person.id)
                                    if selectedPeople.count == event.people.count {
                                        selectAll = true
                                    }
                                } else {
                                    selectedPeople.remove(person.id)
                                    selectAll = false
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(itemName.isEmpty || itemPrice.isEmpty || selectedPeople.isEmpty)
                }
            }
        }
    }
    
    private func addItem() {
        guard let pricePerItem = Double(itemPrice) else { return }
        
        let newItem = Item(
            name: itemName,
            price: pricePerItem * Double(quantity),
            quantity: quantity,
            sharedBy: Array(selectedPeople)
        )
        event.items.append(newItem)
        dismiss()
    }
}

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var item: Item
    let people: [Person]
    
    @State private var editedName: String
    @State private var editedPrice: String
    @State private var selectedPeople: Set<UUID>
    @State private var selectAll: Bool
    
    init(item: Binding<Item>, people: [Person]) {
        self._item = item
        self.people = people
        self._editedName = State(initialValue: item.wrappedValue.name)
        self._editedPrice = State(initialValue: String(format: "%.2f", item.wrappedValue.price))
        self._selectedPeople = State(initialValue: Set(item.wrappedValue.sharedBy))
        self._selectAll = State(initialValue: Set(item.wrappedValue.sharedBy).count == people.count)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $editedName)
                    TextField("Price", text: $editedPrice)
                        .keyboardType(.decimalPad)
                }
                
                Section("Shared By") {
                    if !people.isEmpty {
                        Toggle("Select All", isOn: Binding(
                            get: { selectAll },
                            set: { newValue in
                                selectAll = newValue
                                if newValue {
                                    selectedPeople = Set(people.map { $0.id })
                                } else {
                                    selectedPeople.removeAll()
                                }
                            }
                        ))
                    }
                    
                    ForEach(people) { person in
                        Toggle(person.name, isOn: Binding(
                            get: { selectedPeople.contains(person.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedPeople.insert(person.id)
                                    if selectedPeople.count == people.count {
                                        selectAll = true
                                    }
                                } else {
                                    selectedPeople.remove(person.id)
                                    selectAll = false
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        item.name = editedName
                        if let newPrice = Double(editedPrice) {
                            item.price = newPrice
                        }
                        item.sharedBy = Array(selectedPeople)
                        dismiss()
                    }
                    .disabled(editedName.isEmpty || 
                            selectedPeople.isEmpty || 
                            Double(editedPrice) == nil)
                }
            }
        }
    }
} 