import SwiftUI
import Foundation

struct BillSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let event: Event
    
    @State private var salesTaxPercentage: Double = 8.875 // Default NYC sales tax
    @State private var tipPercentage: Double = 15.0
    @State private var expandedPeople: Set<UUID> = []
    
    var personTotals: [(person: Person, subtotal: Double, tax: Double, tip: Double, total: Double, items: [(Item, Double)])] {
        event.people.map { person in
            var personItems: [(Item, Double)] = []
            let subtotal = event.items.reduce(0.0) { sum, item in
                if item.sharedBy.contains(person.id) {
                    let shareAmount = item.price / Double(item.sharedBy.count)
                    personItems.append((item, shareAmount))
                    return sum + shareAmount
                }
                return sum
            }
            let tax = subtotal * (salesTaxPercentage / 100.0)
            let tip = (subtotal + tax) * (tipPercentage / 100.0) // Tip calculated after tax
            let total = subtotal + tax + tip
            return (person, subtotal, tax, tip, total, personItems.sorted { $0.1 > $1.1 })
        }.sorted { $0.total > $1.total }
    }
    
    var subtotal: Double {
        event.items.reduce(0) { $0 + $1.price }
    }
    
    var salesTaxAmount: Double {
        subtotal * (salesTaxPercentage / 100.0)
    }
    
    var tipAmount: Double {
        (subtotal + salesTaxAmount) * (tipPercentage / 100.0) // Tip calculated after tax
    }
    
    var totalBill: Double {
        subtotal + salesTaxAmount + tipAmount
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(String(format: "$%.2f", subtotal))
                            .bold()
                    }
                    
                    VStack {
                        HStack {
                            Text("Sales Tax")
                            Spacer()
                            Text(String(format: "$%.2f", salesTaxAmount))
                                .bold()
                        }
                        
                        Slider(value: $salesTaxPercentage, in: 0...15, step: 0.125) {
                            Text("Sales Tax Percentage")
                        } minimumValueLabel: {
                            Text("0%")
                        } maximumValueLabel: {
                            Text("15%")
                        }
                        
                        Text(String(format: "%.3f%%", salesTaxPercentage))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        HStack {
                            Text("Tip")
                            Spacer()
                            Text(String(format: "$%.2f", tipAmount))
                                .bold()
                        }
                        
                        Slider(value: $tipPercentage, in: 0...30, step: 1) {
                            Text("Tip Percentage")
                        } minimumValueLabel: {
                            Text("0%")
                        } maximumValueLabel: {
                            Text("30%")
                        }
                        
                        Text("\(Int(tipPercentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total with Tax & Tip")
                        Spacer()
                        Text(String(format: "$%.2f", totalBill))
                            .bold()
                    }
                }
                
                Section("Individual Totals") {
                    ForEach(personTotals, id: \.person.id) { personTotal in
                        VStack(alignment: .leading, spacing: 4) {
                            Button(action: {
                                toggleExpanded(personTotal.person.id)
                            }) {
                                HStack {
                                    Circle()
                                        .fill(personTotal.person.color)
                                        .frame(width: 10, height: 10)
                                    Text(personTotal.person.name)
                                        .foregroundColor(personTotal.person.color)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(String(format: "$%.2f", personTotal.total))
                                            .bold()
                                        Group {
                                            Text(String(format: "+$%.2f tax", personTotal.tax))
                                            Text(String(format: "+$%.2f tip", personTotal.tip))
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                    Image(systemName: expandedPeople.contains(personTotal.person.id) ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.gray)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            if expandedPeople.contains(personTotal.person.id) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(String(format: "Subtotal: $%.2f", personTotal.subtotal))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading)
                                    
                                    ForEach(personTotal.items, id: \.0.id) { item, share in
                                        HStack {
                                            Text("• \(item.name)")
                                                .foregroundColor(.secondary)
                                            if item.quantity > 1 {
                                                Text("×\(item.quantity)")
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Text(String(format: "$%.2f", share))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.leading)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                
                Section("Items Breakdown") {
                    ForEach(event.items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.name)
                                if item.quantity > 1 {
                                    Text("×\(item.quantity)")
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(String(format: "$%.2f", item.price))
                            }
                            .bold()
                            
                            if item.quantity > 1 {
                                Text(String(format: "($%.2f each)", item.price / Double(item.quantity)))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                // Color dots for people sharing this item
                                ForEach(event.people.filter { item.sharedBy.contains($0.id) }, id: \.id) { person in
                                    Circle()
                                        .fill(person.color)
                                        .frame(width: 10, height: 10)
                                }
                                Spacer()
                                Text(String(format: "($%.2f per person)", item.price / Double(item.sharedBy.count)))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            let sharedBy = event.people
                                .filter { item.sharedBy.contains($0.id) }
                                .map { $0.name }
                            
                            Text("Split between: \(sharedBy.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Bill Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleExpanded(_ id: UUID) {
        if expandedPeople.contains(id) {
            expandedPeople.remove(id)
        } else {
            expandedPeople.insert(id)
        }
    }
} 