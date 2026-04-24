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

    /// メンバーを配偶者ペアとシングルに分離（親ペア単位でグルーピングして兄弟を連続配置）
    private func groupBySpouse(members: [FamilyMember]) -> (pairs: [(FamilyMember, FamilyMember)], singles: [FamilyMember]) {
        // 親ペアキーでグループ分けし、同じ親ペアの子が横並びになるよう順序を決める
        let sortedMembers = sortByParentGroup(members: members)

        var pairs: [(FamilyMember, FamilyMember)] = []
        var processedIds = Set<UUID>()
        var singles: [FamilyMember] = []

        for member in sortedMembers {
            guard !processedIds.contains(member.id) else { continue }

            // 現配偶者（離婚していない）がこの世代にいれば、ペアとして配置
            if let spouse = member.currentSpouse,
               sortedMembers.contains(where: { $0.id == spouse.id }) {
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

    /// 同世代のメンバーを「親ペアキー」でソートし、同じ親ペアの子が連続するように並べ替え
    private func sortByParentGroup(members: [FamilyMember]) -> [FamilyMember] {
        var groupOrder: [String] = []
        var membersByGroup: [String: [FamilyMember]] = [:]

        for member in members {
            let key = parentGroupKey(for: member)
            if membersByGroup[key] == nil {
                groupOrder.append(key)
            }
            membersByGroup[key, default: []].append(member)
        }

        return groupOrder.flatMap { membersByGroup[$0] ?? [] }
    }

    /// 親ペアキー（ソート済み親IDの連結文字列、親が無ければ "_root_"）
    private func parentGroupKey(for member: FamilyMember) -> String {
        if member.parents.isEmpty {
            return "_root_\(member.id.uuidString)"
        }
        return member.parents.map { $0.id.uuidString }.sorted().joined(separator: "-")
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

        // 1. 親子接続 / 兄弟バス線（兄弟2人以上なら T字でまとめる）
        connections.append(contentsOf: generateParentChildConnections(nodes: nodes, tree: tree))

        // 2. 配偶者接続（現婚は二重線、離別は破線）
        connections.append(contentsOf: generateSpouseConnections(nodes: nodes, tree: tree))

        return connections
    }

    /// 親子接続と兄弟バス線を生成
    private func generateParentChildConnections(nodes: [UUID: TreeNode], tree: FamilyTree) -> [TreeConnection] {
        var connections: [TreeConnection] = []
        var processedParentGroupKeys = Set<String>()

        for member in tree.members {
            guard !member.children.isEmpty else { continue }

            for child in member.children {
                // 親ペアキー（両親の ID を昇順連結）で兄弟グループを一意化
                let parentKey = child.parents.map { $0.id.uuidString }.sorted().joined(separator: "-")
                guard !parentKey.isEmpty else { continue }
                guard !processedParentGroupKeys.contains(parentKey) else { continue }
                processedParentGroupKeys.insert(parentKey)

                // この親グループの全兄弟を収集
                let siblings = tree.members.filter {
                    !$0.parents.isEmpty &&
                    $0.parents.map { $0.id.uuidString }.sorted().joined(separator: "-") == parentKey
                }
                let siblingNodes = siblings.compactMap { nodes[$0.id] }
                guard !siblingNodes.isEmpty else { continue }

                // 親ノード中心点（両親の下端中央の平均）
                let parentNodes = child.parents.compactMap { nodes[$0.id] }
                guard !parentNodes.isEmpty else { continue }
                let parentCenterX = parentNodes.map { $0.bottomCenter.x }.reduce(0, +) / CGFloat(parentNodes.count)
                let parentBottomY = parentNodes.map { $0.bottomCenter.y }.max() ?? 0
                let parentAnchor = CGPoint(x: parentCenterX, y: parentBottomY)

                // ハイライト判定用の ID 集合（親 + 兄弟全員）
                let parentIds = Set(child.parents.map { $0.id })
                let siblingIds = Set(siblings.map { $0.id })
                let groupIds = parentIds.union(siblingIds)

                if siblingNodes.count >= 2 {
                    // 兄弟バス線（T字）
                    let busY = parentBottomY + verticalSpacing / 2

                    // 親 → バス Y（縦線、親子色）
                    connections.append(TreeConnection(
                        from: parentAnchor,
                        to: CGPoint(x: parentCenterX, y: busY),
                        connectionType: .parentChild,
                        memberIds: groupIds
                    ))

                    // バス横線（左端 → 右端、兄弟色）
                    let childXs = siblingNodes.map { $0.topCenter.x }
                    let minX = min(parentCenterX, childXs.min() ?? parentCenterX)
                    let maxX = max(parentCenterX, childXs.max() ?? parentCenterX)
                    connections.append(TreeConnection(
                        from: CGPoint(x: minX, y: busY),
                        to: CGPoint(x: maxX, y: busY),
                        connectionType: .siblingBus,
                        memberIds: groupIds
                    ))

                    // バス → 各子の上端（縦線）
                    for (sibling, childNode) in zip(siblings, siblingNodes) {
                        connections.append(TreeConnection(
                            from: CGPoint(x: childNode.topCenter.x, y: busY),
                            to: childNode.topCenter,
                            connectionType: .parentChild,
                            memberIds: parentIds.union([sibling.id])
                        ))
                    }
                } else if let soloNode = siblingNodes.first, let solo = siblings.first {
                    // 兄弟 1 人: 従来の階段状
                    connections.append(TreeConnection(
                        from: parentAnchor,
                        to: soloNode.topCenter,
                        connectionType: .parentChild,
                        memberIds: parentIds.union([solo.id])
                    ))
                }
            }
        }

        return connections
    }

    /// 配偶者接続を生成（現婚・離婚で別スタイル）
    private func generateSpouseConnections(nodes: [UUID: TreeNode], tree: FamilyTree) -> [TreeConnection] {
        var connections: [TreeConnection] = []
        var processedMarriageIds = Set<UUID>()

        for member in tree.members {
            guard let node = nodes[member.id] else { continue }

            for marriage in member.marriages {
                guard !processedMarriageIds.contains(marriage.id) else { continue }
                processedMarriageIds.insert(marriage.id)

                guard let spouse = marriage.getSpouse(of: member),
                      let spouseNode = nodes[spouse.id] else { continue }

                // 隣接判定（X 座標差が閾値以内か）
                let xDiff = abs(node.position.x - spouseNode.position.x)
                let adjacencyThreshold = nodeSize.width + horizontalSpacing * 1.2
                let isAdjacent = xDiff <= adjacencyThreshold

                let fromPoint: CGPoint
                let toPoint: CGPoint
                if node.position.x < spouseNode.position.x {
                    fromPoint = node.rightCenter
                    toPoint = spouseNode.leftCenter
                } else {
                    fromPoint = node.leftCenter
                    toPoint = spouseNode.rightCenter
                }

                let type: ConnectionType = marriage.isCurrentlyMarried ? .currentSpouse : .divorcedSpouse
                connections.append(TreeConnection(
                    from: fromPoint,
                    to: toPoint,
                    connectionType: type,
                    isAdjacent: isAdjacent,
                    memberIds: [member.id, spouse.id]
                ))
            }
        }

        return connections
    }
}
