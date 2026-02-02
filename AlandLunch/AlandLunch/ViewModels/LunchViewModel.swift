import Foundation
import SwiftUI

@MainActor
class LunchViewModel: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastUpdated: Date?

    private let scraper = WebScraper()
    private let settings = SettingsManager.shared

    var visibleRestaurants: [Restaurant] {
        restaurants.filter { settings.isRestaurantVisible($0.id) }
    }

    var allRestaurantNames: [(id: String, name: String)] {
        restaurants.map { ($0.id, $0.name) }.sorted { $0.name < $1.name }
    }

    init() {
        loadCachedData()
    }

    private func loadCachedData() {
        if let cached = settings.loadCachedLunchData() {
            self.restaurants = cached.restaurants
            self.lastUpdated = cached.fetchedAt

            // Auto-refresh if data is stale
            if cached.isStale {
                Task {
                    await refresh()
                }
            }
        }
    }

    func refresh() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let fetchedRestaurants = try await scraper.fetchRestaurants()

            if fetchedRestaurants.isEmpty {
                // If scraper returns empty, keep cached data but show warning
                if restaurants.isEmpty {
                    error = "No restaurants found. The website structure may have changed."
                }
            } else {
                restaurants = fetchedRestaurants
                lastUpdated = Date()

                // Cache the data
                let lunchData = LunchData(restaurants: fetchedRestaurants, fetchedAt: Date())
                settings.saveLunchData(lunchData)
            }
        } catch {
            self.error = error.localizedDescription
            // Keep showing cached data if available
        }

        isLoading = false
    }

    var formattedLastUpdated: String? {
        guard let lastUpdated = lastUpdated else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
}
