import SwiftUI
import MapKit
import AsaUIKit
import AsaCommunityKit

/// 避難所マップ画面
struct ShelterMapView: View {
    let shelters: [EvacuationShelter]
    @State private var selectedShelter: EvacuationShelter?

    var body: some View {
        ZStack {
            Map(selection: $selectedShelter) {
                ForEach(shelters) { shelter in
                    Annotation(shelter.name, coordinate: CLLocationCoordinate2D(
                        latitude: shelter.latitude,
                        longitude: shelter.longitude
                    )) {
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(shelter.isOpen ? .red : .gray)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "cross.case.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                            }
                            Triangle()
                                .fill(shelter.isOpen ? .red : .gray)
                                .frame(width: 12, height: 8)
                                .offset(y: -2)
                        }
                    }
                    .tag(shelter)
                }
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }

            // 選択された避難所の詳細
            if let shelter = selectedShelter {
                VStack {
                    Spacer()
                    shelterDetailCard(shelter)
                }
            }
        }
    }

    private func shelterDetailCard(_ shelter: EvacuationShelter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(shelter.name)
                    .font(.headline)
                Spacer()
                Button {
                    selectedShelter = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            Text(shelter.address)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 16) {
                VStack {
                    Text("収容人数")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(shelter.currentOccupancy)/\(shelter.capacity)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                VStack {
                    Text("設備")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(shelter.facilitiesText)
                        .font(.caption)
                }
                Spacer()
                if shelter.isOpen {
                    Text("開設中")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.2))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
            }

            if !shelter.phoneNumber.isEmpty {
                Label(shelter.phoneNumber, systemImage: "phone.fill")
                    .font(.caption)
                    .foregroundStyle(AsaColors.coffeeBrown)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
}
