import SwiftUI
import MapKit
import AsaUIKit
import AsaCommunityKit

/// 店舗詳細画面
struct BusinessDetailView: View {
    let business: LocalBusiness
    @Bindable var viewModel: LocalBusinessViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Map
                if business.latitude != 0 && business.longitude != 0 {
                    Map {
                        Marker(business.name, coordinate: CLLocationCoordinate2D(
                            latitude: business.latitude,
                            longitude: business.longitude
                        ))
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // MARK: - Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(business.category.rawValue, systemImage: business.category.iconName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AsaColors.softCream)
                            .clipShape(Capsule())
                        Text(business.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AsaColors.darkSlate)
                    }
                    Spacer()
                    Button {
                        viewModel.toggleFavorite(business)
                    } label: {
                        Image(systemName: business.isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(business.isFavorite ? .red : .secondary)
                    }
                }

                // MARK: - Details
                VStack(alignment: .leading, spacing: 10) {
                    if !business.businessDescription.isEmpty {
                        Text(business.businessDescription)
                            .font(.body)
                    }

                    Divider()

                    Label(business.address, systemImage: "mappin.circle")
                        .font(.subheadline)

                    if !business.phoneNumber.isEmpty {
                        Label(business.phoneNumber, systemImage: "phone")
                            .font(.subheadline)
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }

                    if !business.businessHours.isEmpty {
                        Label(business.businessHours, systemImage: "clock")
                            .font(.subheadline)
                    }

                    if !business.closedDays.isEmpty {
                        Label("定休日: \(business.closedDays)", systemImage: "calendar.badge.minus")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(business.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
