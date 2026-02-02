import SwiftUI

struct LunchListView: View {
    @StateObject private var viewModel = LunchViewModel()
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading && viewModel.restaurants.isEmpty {
                    loadingView
                } else if let error = viewModel.error, viewModel.restaurants.isEmpty {
                    errorView(error)
                } else if viewModel.visibleRestaurants.isEmpty {
                    emptyView
                } else {
                    restaurantList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Lunch")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .symbolVariant(settings.hiddenRestaurantIDs.isEmpty ? .none : .fill)
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(restaurants: viewModel.allRestaurantNames)
            }
            .overlay(alignment: .bottom) {
                if viewModel.isLoading && !viewModel.restaurants.isEmpty {
                    loadingIndicator
                }
            }
            .task {
                if viewModel.restaurants.isEmpty {
                    await viewModel.refresh()
                }
            }
        }
    }

    private var restaurantList: some View {
        LazyVStack(spacing: 12) {
            if let lastUpdated = viewModel.formattedLastUpdated {
                HStack {
                    Text("Updated \(lastUpdated)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            ForEach(viewModel.visibleRestaurants) { restaurant in
                RestaurantCardView(restaurant: restaurant)
                    .padding(.horizontal, 16)
            }

            // Bottom padding for safe area
            Color.clear.frame(height: 20)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading menus...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    private var loadingIndicator: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("Updating...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.bottom, 16)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Unable to load menus")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "fork.knife")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            if viewModel.restaurants.isEmpty {
                Text("No menus available")
                    .font(.headline)
                Text("Pull to refresh")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("All restaurants hidden")
                    .font(.headline)
                Text("Tap the filter icon to show restaurants")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    showingSettings = true
                } label: {
                    Label("Show Restaurants", systemImage: "eye")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
}

#Preview {
    LunchListView()
}
