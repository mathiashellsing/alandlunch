import Foundation
import SwiftUI

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let hiddenRestaurantsKey = "hiddenRestaurants"
    private let cachedDataKey = "cachedLunchData"

    @Published var hiddenRestaurantIDs: Set<String> {
        didSet {
            saveHiddenRestaurants()
        }
    }

    private init() {
        if let data = UserDefaults.standard.array(forKey: hiddenRestaurantsKey) as? [String] {
            self.hiddenRestaurantIDs = Set(data)
        } else {
            self.hiddenRestaurantIDs = []
        }
    }

    private func saveHiddenRestaurants() {
        UserDefaults.standard.set(Array(hiddenRestaurantIDs), forKey: hiddenRestaurantsKey)
    }

    func isRestaurantVisible(_ id: String) -> Bool {
        !hiddenRestaurantIDs.contains(id)
    }

    func toggleRestaurant(_ id: String) {
        if hiddenRestaurantIDs.contains(id) {
            hiddenRestaurantIDs.remove(id)
        } else {
            hiddenRestaurantIDs.insert(id)
        }
    }

    func setRestaurantHidden(_ id: String, hidden: Bool) {
        if hidden {
            hiddenRestaurantIDs.insert(id)
        } else {
            hiddenRestaurantIDs.remove(id)
        }
    }

    // MARK: - Cache Management

    func saveLunchData(_ data: LunchData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cachedDataKey)
        }
    }

    func loadCachedLunchData() -> LunchData? {
        guard let data = UserDefaults.standard.data(forKey: cachedDataKey),
              let decoded = try? JSONDecoder().decode(LunchData.self, from: data) else {
            return nil
        }
        return decoded
    }

    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cachedDataKey)
    }
}
