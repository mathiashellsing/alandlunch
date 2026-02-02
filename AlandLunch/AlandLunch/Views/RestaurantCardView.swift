import SwiftUI

struct RestaurantCardView: View {
    let restaurant: Restaurant
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        if let phone = restaurant.phone {
                            Label(phone, systemImage: "phone")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.leading, 16)

                // Menu Items
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(restaurant.sections) { section in
                        if !section.title.isEmpty && restaurant.sections.count > 1 {
                            Text(section.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                        }

                        ForEach(section.items) { item in
                            MenuItemRow(item: item)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct MenuItemRow: View {
    let item: MenuItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(item.price)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.orange)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    let sampleRestaurant = Restaurant(
        id: "sample",
        name: "Bagarstugan Café",
        phone: "+358 18 19880",
        sections: [
            MenuSection(
                title: "Stående rätter",
                items: [
                    MenuItem(category: "Kalla Smörgåsar", name: "Kalla Smörgåsar", description: "Välj mellan Ost & Skinka eller Medwurst & Saltgurka", price: "7.50€"),
                    MenuItem(category: "Varma Smörgåsar", name: "Varma Smörgåsar", description: "Ost & Skinka", price: "9.50€")
                ]
            )
        ]
    )

    return RestaurantCardView(restaurant: sampleRestaurant)
        .padding()
        .background(Color(.systemGroupedBackground))
}
