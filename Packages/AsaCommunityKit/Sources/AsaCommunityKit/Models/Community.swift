import Foundation
import SwiftData

// MARK: - Community

/// コミュニティ（町内会・自治会）モデル
@Model
public final class Community {
    public var id: UUID = UUID()
    public var name: String = ""
    public var area: String = ""
    public var welcomeMessage: String = ""
    public var memberCount: Int = 0
    public var latitude: Double = 0.0
    public var longitude: Double = 0.0
    public var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \CommunityPost.community)
    public var posts: [CommunityPost] = []

    @Relationship(deleteRule: .cascade, inverse: \CommunityEvent.community)
    public var events: [CommunityEvent] = []

    public init(
        name: String,
        area: String,
        welcomeMessage: String = "",
        memberCount: Int = 0,
        latitude: Double = 0.0,
        longitude: Double = 0.0
    ) {
        self.id = UUID()
        self.name = name
        self.area = area
        self.welcomeMessage = welcomeMessage
        self.memberCount = memberCount
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = Date()
    }
}
