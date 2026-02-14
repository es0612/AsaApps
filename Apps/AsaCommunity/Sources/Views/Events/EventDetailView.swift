import SwiftUI
import MapKit
import AsaUIKit
import AsaCommunityKit

/// イベント詳細画面
struct EventDetailView: View {
    let event: CommunityEvent
    @Bindable var viewModel: EventCalendarViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Map
                if event.latitude != 0 && event.longitude != 0 {
                    Map {
                        Marker(event.title, coordinate: CLLocationCoordinate2D(
                            latitude: event.latitude,
                            longitude: event.longitude
                        ))
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // MARK: - Title
                Text(event.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AsaColors.darkSlate)

                // MARK: - Date & Location
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                            + Text(" 〜 ")
                            + Text(event.endDate.formatted(date: .omitted, time: .shortened))
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                    .font(.subheadline)

                    Label(event.location, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // MARK: - Description
                if !event.eventDescription.isEmpty {
                    Text(event.eventDescription)
                        .font(.body)
                        .lineSpacing(6)
                }

                // MARK: - Participants
                VStack(alignment: .leading, spacing: 8) {
                    Text("参加状況")
                        .font(.headline)

                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(AsaColors.coffeeBrown)
                        Text("\(event.attendeeCount)人が参加")
                        if let remaining = event.remainingSlots {
                            Text("（残り\(remaining)枠）")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                }

                Divider()

                // MARK: - RSVP Buttons
                if !event.isPast {
                    VStack(spacing: 10) {
                        Text("参加しますか？")
                            .font(.headline)

                        HStack(spacing: 12) {
                            ForEach(RSVPStatus.allCases, id: \.self) { status in
                                Button {
                                    Task {
                                        await viewModel.rsvpToEvent(event, status: status)
                                    }
                                } label: {
                                    Label(status.rawValue, systemImage: status.iconName)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            status == .attending ? AsaColors.coffeeBrown : Color(.systemGray5)
                                        )
                                        .foregroundStyle(
                                            status == .attending ? .white : .primary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                } else {
                    Text("このイベントは終了しました")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
        .navigationTitle("イベント詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}
