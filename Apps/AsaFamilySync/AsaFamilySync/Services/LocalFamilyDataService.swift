import Foundation

/// UserDefaultsベースのローカル家族データサービス
/// シミュレータでの動作確認用
class LocalFamilyDataService: FamilyDataService {
    // MARK: - UserDefaults Keys

    private let groupsKey = "AsaFamilySync.Groups"
    private func membersKey(groupId: String) -> String {
        "AsaFamilySync.Members.\(groupId)"
    }
    private func eventsKey(groupId: String) -> String {
        "AsaFamilySync.Events.\(groupId)"
    }

    // MARK: - FamilyDataService Protocol - Group Management

    func createFamilyGroup(
        name: String,
        description: String?,
        ownerId: String,
        ownerName: String,
        ownerEmail: String
    ) async throws -> (group: FamilyGroup, groupId: String) {
        // グループIDを生成
        let groupId = UUID().uuidString

        // グループを作成
        var group = FamilyGroup(name: name, description: description, ownerId: ownerId)
        group.id = groupId

        // グループリストに追加
        var groups = try loadAllGroups()
        groups.append(group)
        try saveGroups(groups)

        // オーナーをメンバーとして追加
        var owner = FamilyMember(userId: ownerId, name: ownerName, email: ownerEmail, role: .owner)
        owner.id = ownerId
        try saveMembers([owner], for: groupId)

        return (group, groupId)
    }

    func joinFamilyGroup(
        inviteCode: String,
        userId: String,
        userName: String,
        userEmail: String
    ) async throws -> (group: FamilyGroup, groupId: String) {
        // 招待コードでグループを検索
        let groups = try loadAllGroups()
        guard let group = groups.first(where: { $0.inviteCode.uppercased() == inviteCode.uppercased() }),
              let groupId = group.id else {
            throw DataServiceError.invalidInviteCode
        }

        // メンバー数確認
        let members = try loadMembers(for: groupId)
        if members.count >= group.maxMembers {
            throw DataServiceError.maxMembersReached
        }

        // 既にメンバーかチェック
        if members.contains(where: { $0.userId == userId }) {
            throw DataServiceError.alreadyMember
        }

        // メンバーとして追加
        var newMember = FamilyMember(userId: userId, name: userName, email: userEmail, role: .member)
        newMember.id = userId

        var updatedMembers = members
        updatedMembers.append(newMember)
        try saveMembers(updatedMembers, for: groupId)

        return (group, groupId)
    }

    func fetchFamilyGroup(groupId: String) async throws -> FamilyGroup {
        let groups = try loadAllGroups()
        guard let group = groups.first(where: { $0.id == groupId }) else {
            throw DataServiceError.groupNotFound
        }
        return group
    }

    func fetchFamilyMembers(groupId: String) async throws -> [FamilyMember] {
        return try loadMembers(for: groupId)
    }

    func removeMember(groupId: String, memberId: String) async throws {
        var members = try loadMembers(for: groupId)
        members.removeAll { $0.userId == memberId }
        try saveMembers(members, for: groupId)
    }

    func updateMemberRole(groupId: String, memberId: String, newRole: MemberRole) async throws {
        var members = try loadMembers(for: groupId)
        guard let index = members.firstIndex(where: { $0.userId == memberId }) else {
            throw DataServiceError.memberNotFound
        }

        members[index].role = newRole
        try saveMembers(members, for: groupId)
    }

    func regenerateInviteCode(groupId: String) async throws -> String {
        var groups = try loadAllGroups()
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else {
            throw DataServiceError.groupNotFound
        }

        let newCode = FamilyGroup.generateInviteCode()
        groups[index].inviteCode = newCode
        groups[index].updatedAt = Date()
        try saveGroups(groups)

        return newCode
    }

    func leaveFamilyGroup(groupId: String, userId: String) async throws {
        try await removeMember(groupId: groupId, memberId: userId)
    }

    // MARK: - FamilyDataService Protocol - Event Management

    func createEvent(groupId: String, event: FamilyEvent) async throws -> String {
        let eventId = UUID().uuidString
        var newEvent = event
        newEvent.id = eventId

        var events = try loadEvents(for: groupId)
        events.append(newEvent)
        try saveEvents(events, for: groupId)

        return eventId
    }

    func updateEvent(groupId: String, eventId: String, event: FamilyEvent) async throws {
        var events = try loadEvents(for: groupId)
        guard let index = events.firstIndex(where: { $0.id == eventId }) else {
            throw DataServiceError.unknown("イベントが見つかりません")
        }

        var updatedEvent = event
        updatedEvent.id = eventId
        updatedEvent.updatedAt = Date()
        events[index] = updatedEvent
        try saveEvents(events, for: groupId)
    }

    func deleteEvent(groupId: String, eventId: String) async throws {
        var events = try loadEvents(for: groupId)
        events.removeAll { $0.id == eventId }
        try saveEvents(events, for: groupId)
    }

    func fetchEvents(groupId: String) async throws -> [FamilyEvent] {
        return try loadEvents(for: groupId)
    }

    func fetchEvents(groupId: String, from startDate: Date, to endDate: Date) async throws -> [FamilyEvent] {
        let allEvents = try loadEvents(for: groupId)
        return allEvents.filter { event in
            event.startTime >= startDate && event.startTime <= endDate
        }
    }

    // MARK: - Private Methods - Groups

    private func loadAllGroups() throws -> [FamilyGroup] {
        guard let data = UserDefaults.standard.data(forKey: groupsKey) else {
            return []
        }
        return try JSONDecoder().decode([FamilyGroup].self, from: data)
    }

    private func saveGroups(_ groups: [FamilyGroup]) throws {
        let data = try JSONEncoder().encode(groups)
        UserDefaults.standard.set(data, forKey: groupsKey)
    }

    // MARK: - Private Methods - Members

    private func loadMembers(for groupId: String) throws -> [FamilyMember] {
        let key = membersKey(groupId: groupId)
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        return try JSONDecoder().decode([FamilyMember].self, from: data)
    }

    private func saveMembers(_ members: [FamilyMember], for groupId: String) throws {
        let key = membersKey(groupId: groupId)
        let data = try JSONEncoder().encode(members)
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Private Methods - Events

    private func loadEvents(for groupId: String) throws -> [FamilyEvent] {
        let key = eventsKey(groupId: groupId)
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        return try JSONDecoder().decode([FamilyEvent].self, from: data)
    }

    private func saveEvents(_ events: [FamilyEvent], for groupId: String) throws {
        let key = eventsKey(groupId: groupId)
        let data = try JSONEncoder().encode(events)
        UserDefaults.standard.set(data, forKey: key)
    }
}
