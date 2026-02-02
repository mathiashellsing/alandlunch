import Foundation

struct MenuItem: Identifiable, Codable, Equatable {
    let id: UUID
    let category: String
    let name: String
    let description: String?
    let price: String

    init(id: UUID = UUID(), category: String, name: String, description: String? = nil, price: String) {
        self.id = id
        self.category = category
        self.name = name
        self.description = description
        self.price = price
    }
}

struct MenuSection: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let items: [MenuItem]

    init(id: UUID = UUID(), title: String, items: [MenuItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

struct Restaurant: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let phone: String?
    let imageURL: String?
    let sections: [MenuSection]

    init(id: String, name: String, phone: String? = nil, imageURL: String? = nil, sections: [MenuSection]) {
        self.id = id
        self.name = name
        self.phone = phone
        self.imageURL = imageURL
        self.sections = sections
    }

    var allMenuItems: [MenuItem] {
        sections.flatMap { $0.items }
    }
}

struct LunchData: Codable {
    let restaurants: [Restaurant]
    let fetchedAt: Date

    var isStale: Bool {
        let calendar = Calendar.current
        return !calendar.isDateInToday(fetchedAt)
    }
}
