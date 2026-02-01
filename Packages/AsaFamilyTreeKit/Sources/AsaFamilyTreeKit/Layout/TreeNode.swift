import Foundation
import CoreGraphics

/// ツリー描画用のノード構造体
public struct TreeNode: Identifiable, Sendable {
    public let id: UUID
    public let member: MemberSnapshot
    public var position: CGPoint
    public var size: CGSize
    public let generation: Int

    // MARK: - Initializer

    public init(
        member: FamilyMember,
        position: CGPoint = .zero,
        size: CGSize = CGSize(width: 120, height: 80),
        generation: Int = 0
    ) {
        self.id = member.id
        self.member = MemberSnapshot(member: member)
        self.position = position
        self.size = size
        self.generation = generation
    }

    // MARK: - Computed Properties

    /// ノードの中心点
    public var center: CGPoint {
        CGPoint(
            x: position.x + size.width / 2,
            y: position.y + size.height / 2
        )
    }

    /// ノードの上端中央（親への接続点）
    public var topCenter: CGPoint {
        CGPoint(
            x: position.x + size.width / 2,
            y: position.y
        )
    }

    /// ノードの下端中央（子への接続点）
    public var bottomCenter: CGPoint {
        CGPoint(
            x: position.x + size.width / 2,
            y: position.y + size.height
        )
    }

    /// ノードの左端中央（配偶者への接続点）
    public var leftCenter: CGPoint {
        CGPoint(
            x: position.x,
            y: position.y + size.height / 2
        )
    }

    /// ノードの右端中央（配偶者への接続点）
    public var rightCenter: CGPoint {
        CGPoint(
            x: position.x + size.width,
            y: position.y + size.height / 2
        )
    }

    /// ノードのフレーム
    public var frame: CGRect {
        CGRect(origin: position, size: size)
    }
}

// MARK: - MemberSnapshot

/// メンバー情報のスナップショット（Sendable対応）
public struct MemberSnapshot: Sendable {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public let gender: Gender
    public let birthDate: Date?
    public let deathDate: Date?
    public let hasProfileImage: Bool
    public let parentIds: [UUID]
    public let childIds: [UUID]
    public let spouseIds: [UUID]

    public init(member: FamilyMember) {
        self.id = member.id
        self.firstName = member.firstName
        self.lastName = member.lastName
        self.gender = member.gender
        self.birthDate = member.birthDate
        self.deathDate = member.deathDate
        self.hasProfileImage = member.hasProfileImage
        self.parentIds = member.parents.map { $0.id }
        self.childIds = member.children.map { $0.id }
        self.spouseIds = member.spouses.map { $0.id }
    }

    // MARK: - Computed Properties

    public var fullName: String {
        "\(lastName) \(firstName)"
    }

    public var isAlive: Bool {
        deathDate == nil
    }

    public var lifeSpanString: String {
        let birthYear = birthDate.map { Calendar.current.component(.year, from: $0) }
        let deathYear = deathDate.map { Calendar.current.component(.year, from: $0) }

        switch (birthYear, deathYear) {
        case let (.some(birth), .some(death)):
            return "\(birth) - \(death)"
        case let (.some(birth), .none):
            return "\(birth) -"
        case let (.none, .some(death)):
            return "- \(death)"
        case (.none, .none):
            return ""
        }
    }
}

// MARK: - TreeConnection

/// ノード間の接続線を表す構造体
public struct TreeConnection: Identifiable, Sendable {
    public let id: UUID
    public let from: CGPoint
    public let to: CGPoint
    public let connectionType: ConnectionType

    public init(from: CGPoint, to: CGPoint, connectionType: ConnectionType) {
        self.id = UUID()
        self.from = from
        self.to = to
        self.connectionType = connectionType
    }
}

// MARK: - ConnectionType

/// 接続線の種類
public enum ConnectionType: Sendable {
    case parentChild    // 親子関係（縦線）
    case spouse         // 配偶者関係（横線）

    /// 線の色
    public var lineColor: CGColor {
        switch self {
        case .parentChild:
            return CGColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        case .spouse:
            return CGColor(red: 0.8, green: 0.4, blue: 0.5, alpha: 1.0)
        }
    }

    /// 線の太さ
    public var lineWidth: CGFloat {
        switch self {
        case .parentChild: return 2.0
        case .spouse: return 2.5
        }
    }
}

// MARK: - TreeLayout

/// ツリーレイアウトの結果
public struct TreeLayout: Sendable {
    public let nodes: [TreeNode]
    public let connections: [TreeConnection]
    public let bounds: CGRect

    public init(nodes: [TreeNode], connections: [TreeConnection]) {
        self.nodes = nodes
        self.connections = connections

        // 全ノードを包含する境界を計算
        if nodes.isEmpty {
            self.bounds = .zero
        } else {
            var minX = CGFloat.infinity
            var minY = CGFloat.infinity
            var maxX = -CGFloat.infinity
            var maxY = -CGFloat.infinity

            for node in nodes {
                minX = min(minX, node.position.x)
                minY = min(minY, node.position.y)
                maxX = max(maxX, node.position.x + node.size.width)
                maxY = max(maxY, node.position.y + node.size.height)
            }

            self.bounds = CGRect(
                x: minX - 50,
                y: minY - 50,
                width: maxX - minX + 100,
                height: maxY - minY + 100
            )
        }
    }
}
