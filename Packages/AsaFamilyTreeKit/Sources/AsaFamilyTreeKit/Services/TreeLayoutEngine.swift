import Foundation
import CoreGraphics

/// ツリーレイアウト計算エンジン
/// 世代ベースのレイアウトアルゴリズムを実装
@MainActor
public final class TreeLayoutEngine {
    // MARK: - Configuration

    /// ノードのデフォルトサイズ
    public var nodeSize: CGSize = CGSize(width: 120, height: 80)

    /// ノード間の水平間隔
    public var horizontalSpacing: CGFloat = 40

    /// 世代間の垂直間隔
    public var verticalSpacing: CGFloat = 100

    /// 配偶者間の間隔
    public var spouseSpacing: CGFloat = 20

    // MARK: - Initializer

    public init() {}

    // MARK: - Layout Calculation

    /// 家系図のレイアウトを計算
    public func calculateLayout(for tree: FamilyTree) -> TreeLayout {
        guard !tree.members.isEmpty else {
            return TreeLayout(nodes: [], connections: [])
        }

        // 世代を計算
        tree.calculateGenerations()

        // 世代別にメンバーをグループ化
        let membersByGeneration = tree.membersByGeneration()
        let sortedGenerations = membersByGeneration.keys.sorted()

        // ノードを作成
        var nodes: [UUID: TreeNode] = [:]
        var nodePositions: [UUID: CGPoint] = [:]

        // 各世代のレイアウトを計算
        for generation in sortedGenerations {
            guard let membersInGeneration = membersByGeneration[generation] else { continue }

            // 配偶者ペアとシングルメンバーを分離
            let (pairs, singles) = groupBySpouse(members: membersInGeneration)

            // Y座標を計算
            let y = CGFloat(generation) * (nodeSize.height + verticalSpacing)

            // 配偶者ペアを配置
            var currentX: CGFloat = 0

            for pair in pairs {
                // 左側のパートナー
                let leftPosition = CGPoint(x: currentX, y: y)
                nodePositions[pair.0.id] = leftPosition
                nodes[pair.0.id] = TreeNode(member: pair.0, position: leftPosition, size: nodeSize, generation: generation)

                currentX += nodeSize.width + spouseSpacing

                // 右側のパートナー
                let rightPosition = CGPoint(x: currentX, y: y)
                nodePositions[pair.1.id] = rightPosition
                nodes[pair.1.id] = TreeNode(member: pair.1, position: rightPosition, size: nodeSize, generation: generation)

                currentX += nodeSize.width + horizontalSpacing
            }

            // シングルメンバーを配置
            for member in singles {
                // すでに配置済みの場合はスキップ
                guard nodePositions[member.id] == nil else { continue }

                let position = CGPoint(x: currentX, y: y)
                nodePositions[member.id] = position
                nodes[member.id] = TreeNode(member: member, position: position, size: nodeSize, generation: generation)

                currentX += nodeSize.width + horizontalSpacing
            }
        }

        // 親の中心に子を配置（2パス目で調整）
        adjustChildPositions(nodes: &nodes, nodePositions: &nodePositions, tree: tree)

        // 接続線を生成
        let connections = generateConnections(nodes: nodes, tree: tree)

        return TreeLayout(nodes: Array(nodes.values), connections: connections)
    }

    // MARK: - Helper Methods

    /// メンバーを配偶者ペアとシングルに分離
    private func groupBySpouse(members: [FamilyMember]) -> (pairs: [(FamilyMember, FamilyMember)], singles: [FamilyMember]) {
        var pairs: [(FamilyMember, FamilyMember)] = []
        var processedIds = Set<UUID>()
        var singles: [FamilyMember] = []

        for member in members {
            guard !processedIds.contains(member.id) else { continue }

            // 同じ世代の配偶者を探す
            if let spouse = member.currentSpouse,
               members.contains(where: { $0.id == spouse.id }) {
                pairs.append((member, spouse))
                processedIds.insert(member.id)
                processedIds.insert(spouse.id)
            } else {
                singles.append(member)
                processedIds.insert(member.id)
            }
        }

        return (pairs, singles)
    }

    /// 子の位置を親の中心に調整
    private func adjustChildPositions(nodes: inout [UUID: TreeNode], nodePositions: inout [UUID: CGPoint], tree: FamilyTree) {
        let membersByGeneration = tree.membersByGeneration()
        let sortedGenerations = membersByGeneration.keys.sorted()

        // 上の世代から順に調整
        for generation in sortedGenerations {
            guard let membersInGeneration = membersByGeneration[generation] else { continue }

            for member in membersInGeneration {
                guard !member.children.isEmpty else { continue }

                // 子の現在位置の中心を計算
                let childPositions = member.children.compactMap { nodePositions[$0.id] }
                guard !childPositions.isEmpty else { continue }

                let childCenterX = childPositions.map { $0.x + nodeSize.width / 2 }.reduce(0, +) / CGFloat(childPositions.count)

                // 配偶者がいる場合、ペアの中心に子を配置
                if let spouse = member.currentSpouse,
                   let memberPos = nodePositions[member.id],
                   let spousePos = nodePositions[spouse.id] {
                    let pairCenterX = (memberPos.x + spousePos.x + nodeSize.width) / 2

                    // 子全体を親ペアの中心に移動
                    let offset = pairCenterX - childCenterX

                    for child in member.children {
                        if var childNode = nodes[child.id] {
                            childNode.position.x += offset
                            nodes[child.id] = childNode
                            nodePositions[child.id] = childNode.position
                        }
                    }
                }
            }
        }

        // 重複を解消
        resolveOverlaps(nodes: &nodes, nodePositions: &nodePositions, tree: tree)
    }

    /// ノードの重複を解消
    private func resolveOverlaps(nodes: inout [UUID: TreeNode], nodePositions: inout [UUID: CGPoint], tree: FamilyTree) {
        let membersByGeneration = tree.membersByGeneration()

        for (_, members) in membersByGeneration {
            // X座標でソート
            let sortedMembers = members.sorted { nodePositions[$0.id]?.x ?? 0 < nodePositions[$1.id]?.x ?? 0 }

            // 重複を検出して修正
            for i in 1..<sortedMembers.count {
                let prevMember = sortedMembers[i - 1]
                let currMember = sortedMembers[i]

                guard let prevPos = nodePositions[prevMember.id],
                      var currPos = nodePositions[currMember.id] else { continue }

                let minX = prevPos.x + nodeSize.width + horizontalSpacing

                if currPos.x < minX {
                    // 重複を解消
                    let offset = minX - currPos.x
                    currPos.x = minX
                    nodePositions[currMember.id] = currPos

                    if var node = nodes[currMember.id] {
                        node.position.x += offset
                        nodes[currMember.id] = node
                    }
                }
            }
        }
    }

    /// 接続線を生成
    private func generateConnections(nodes: [UUID: TreeNode], tree: FamilyTree) -> [TreeConnection] {
        var connections: [TreeConnection] = []
        var processedPairs = Set<String>()

        for member in tree.members {
            guard let node = nodes[member.id] else { continue }

            // 親子接続
            for child in member.children {
                guard let childNode = nodes[child.id] else { continue }

                // 重複チェック
                let pairKey = [member.id.uuidString, child.id.uuidString].sorted().joined(separator: "-")
                guard !processedPairs.contains(pairKey) else { continue }
                processedPairs.insert(pairKey)

                // 親の下端から子の上端への接続
                let connection = TreeConnection(
                    from: node.bottomCenter,
                    to: childNode.topCenter,
                    connectionType: .parentChild
                )
                connections.append(connection)
            }

            // 配偶者接続
            for marriage in member.marriages {
                guard let spouse = marriage.getSpouse(of: member),
                      let spouseNode = nodes[spouse.id] else { continue }

                // 重複チェック
                let pairKey = [member.id.uuidString, spouse.id.uuidString].sorted().joined(separator: "-spouse")
                guard !processedPairs.contains(pairKey) else { continue }
                processedPairs.insert(pairKey)

                // 隣り合う配偶者間の接続
                let fromPoint: CGPoint
                let toPoint: CGPoint

                if node.position.x < spouseNode.position.x {
                    fromPoint = node.rightCenter
                    toPoint = spouseNode.leftCenter
                } else {
                    fromPoint = node.leftCenter
                    toPoint = spouseNode.rightCenter
                }

                let connection = TreeConnection(
                    from: fromPoint,
                    to: toPoint,
                    connectionType: .spouse
                )
                connections.append(connection)
            }
        }

        return connections
    }
}
