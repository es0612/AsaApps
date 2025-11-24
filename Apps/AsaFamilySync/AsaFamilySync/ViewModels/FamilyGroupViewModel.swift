import Foundation
#if FIREBASE_ENABLED
import FirebaseFirestore
import FirebaseAuth
#endif

@MainActor
class FamilyGroupViewModel: ObservableObject {
    @Published var familyGroup: FamilyGroup?
    @Published var familyMembers: [FamilyMember] = []
    @Published var familyEvents: [FamilyEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let dataService: FamilyDataService
    private var currentGroupId: String?

    init(dataService: FamilyDataService) {
        self.dataService = dataService
    }

    // MARK: - Group Management

    func createFamilyGroup(name: String, description: String?, userId: String, userName: String, userEmail: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await dataService.createFamilyGroup(
                name: name,
                description: description,
                ownerId: userId,
                ownerName: userName,
                ownerEmail: userEmail
            )

            familyGroup = result.group
            currentGroupId = result.groupId

            // メンバーとイベントも取得
            await refreshData()
        } catch let error as DataServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "家族グループの作成に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func joinFamilyGroup(inviteCode: String, userId: String, userName: String, userEmail: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await dataService.joinFamilyGroup(
                inviteCode: inviteCode,
                userId: userId,
                userName: userName,
                userEmail: userEmail
            )

            familyGroup = result.group
            currentGroupId = result.groupId

            // メンバーとイベントも取得
            await refreshData()
        } catch let error as DataServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "グループへの参加に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadFamilyGroup(groupId: String) async {
        isLoading = true
        errorMessage = nil
        currentGroupId = groupId

        do {
            familyGroup = try await dataService.fetchFamilyGroup(groupId: groupId)
            await refreshData()
        } catch let error as DataServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "グループ情報の取得に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refreshData() async {
        guard let groupId = currentGroupId else { return }

        do {
            // グループ、メンバー、イベントを並行取得
            async let group = dataService.fetchFamilyGroup(groupId: groupId)
            async let members = dataService.fetchFamilyMembers(groupId: groupId)
            async let events = dataService.fetchEvents(groupId: groupId)

            familyGroup = try await group
            familyMembers = try await members
            familyEvents = try await events
        } catch {
            errorMessage = "データの更新に失敗しました: \(error.localizedDescription)"
        }
    }

    func removeMember(memberId: String) async {
        guard let groupId = currentGroupId else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await dataService.removeMember(groupId: groupId, memberId: memberId)
            await refreshData()
        } catch let error as DataServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "メンバーの削除に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func updateMemberRole(memberId: String, newRole: MemberRole) async {
        guard let groupId = currentGroupId else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await dataService.updateMemberRole(groupId: groupId, memberId: memberId, newRole: newRole)
            await refreshData()
        } catch let error as DataServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "権限の変更に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func regenerateInviteCode() async {
        guard let groupId = currentGroupId else { return }

        isLoading = true
        errorMessage = nil

        do {
            let newCode = try await dataService.regenerateInviteCode(groupId: groupId)
            familyGroup?.inviteCode = newCode
            await refreshData()
        } catch let error as DataServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "招待コードの更新に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func leaveFamilyGroup(userId: String) async {
        guard let groupId = currentGroupId else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await dataService.leaveFamilyGroup(groupId: groupId, userId: userId)

            familyGroup = nil
            familyMembers = []
            familyEvents = []
            currentGroupId = nil
        } catch let error as DataServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "グループからの退出に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Event Management

    func createEvent(_ event: FamilyEvent) async {
        guard let groupId = currentGroupId else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await dataService.createEvent(groupId: groupId, event: event)
            await refreshData()
        } catch let error as DataServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "イベントの作成に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func updateEvent(eventId: String, event: FamilyEvent) async {
        guard let groupId = currentGroupId else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await dataService.updateEvent(groupId: groupId, eventId: eventId, event: event)
            await refreshData()
        } catch let error as DataServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "イベントの更新に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func deleteEvent(eventId: String) async {
        guard let groupId = currentGroupId else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await dataService.deleteEvent(groupId: groupId, eventId: eventId)
            await refreshData()
        } catch let error as DataServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "イベントの削除に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func fetchEvents(from startDate: Date, to endDate: Date) async {
        guard let groupId = currentGroupId else { return }

        isLoading = true
        errorMessage = nil

        do {
            familyEvents = try await dataService.fetchEvents(groupId: groupId, from: startDate, to: endDate)
        } catch let error as DataServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "イベントの取得に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
