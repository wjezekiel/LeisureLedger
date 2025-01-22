import SwiftUI
import Foundation

struct Event: Identifiable {
    let id = UUID()
    var name: String
    var date: Date
    var people: [Person]
    var items: [Item]
}

struct Person: Identifiable {
    let id = UUID()
    var name: String
    var itemsShared: Set<UUID> // IDs of items this person is sharing
    var color: Color
    
    init(name: String, itemsShared: Set<UUID> = []) {
        self.name = name
        self.itemsShared = itemsShared
        // Generate a random vibrant color
        self.color = Color(
            hue: Double.random(in: 0...1),
            saturation: 0.7,
            brightness: 0.9
        )
    }
}

struct Item: Identifiable {
    let id = UUID()
    var name: String
    var price: Double      // Total price (price per item * quantity)
    var quantity: Int      // Number of items
    var sharedBy: [UUID]   // IDs of people sharing this item
} 