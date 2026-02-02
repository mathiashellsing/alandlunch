import SwiftUI

struct SettingsView: View {
    let restaurants: [(id: String, name: String)]
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss

    var visibleCount: Int {
        restaurants.filter { settings.isRestaurantVisible($0.id) }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(restaurants, id: \.id) { restaurant in
                        Toggle(isOn: Binding(
                            get: { settings.isRestaurantVisible(restaurant.id) },
                            set: { settings.setRestaurantHidden(restaurant.id, hidden: !$0) }
                        )) {
                            Text(restaurant.name)
                        }
                    }
                } header: {
                    Text("Restaurants")
                } footer: {
                    Text("Toggle restaurants to show or hide them from the main list.")
                }

                Section {
                    Button(role: .none) {
                        withAnimation {
                            settings.hiddenRestaurantIDs.removeAll()
                        }
                    } label: {
                        HStack {
                            Text("Show All")
                            Spacer()
                            Text("\(restaurants.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(visibleCount == restaurants.count)

                    Button(role: .destructive) {
                        withAnimation {
                            restaurants.forEach { settings.hiddenRestaurantIDs.insert($0.id) }
                        }
                    } label: {
                        HStack {
                            Text("Hide All")
                            Spacer()
                            Text("0")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(visibleCount == 0)
                } header: {
                    Text("Quick Actions")
                }

                Section {
                    Button(role: .destructive) {
                        settings.clearCache()
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Clears cached menu data. The app will fetch fresh data on next launch.")
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    SettingsView(restaurants: [
        ("bagarstugan", "Bagarstugan Café"),
        ("dino", "Dino's"),
        ("indigo", "Indigo"),
        ("nautical", "Nautical")
    ])
}
