import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FamilyGroupViewModel: ObservableObject {
    @Published var familyGroup: FamilyGroup?
    @Published var familyMembers: [FamilyMember] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var groupListener: ListenerRegistration?
    private var membersListener: ListenerRegistration?

    deinit {
        groupListener?.remove()
        membersListener?.remove()
    }

    func createFamilyGroup(name: String, description: String?) async {
        isLoading = true
        errorMessage = nil

        guard let userId = Auth.auth().currentUser?.uid,
              let userEmail = Auth.auth().currentUser?.email,
              let userName = Auth.auth().currentUser?.displayName else {
            errorMessage = "ユーザー情報の取得に失敗しました"
            isLoading = false
            return
        }

        let newGroup = FamilyGroup(
            name: name,
            description: description,
            ownerId: userId
        )

        do {
            let docRef = try db.collection("families").addDocument(from: newGroup)
            let groupId = docRef.documentID

            // オーナーをメンバーとして追加
            let ownerMember = FamilyMember(
                userId: userId,
                name: userName,
                email: userEmail,
                role: .owner
            )

            try await db.collection("families").document(groupId)
                .collection("members").document(userId).setData(from: ownerMember)

            // ユーザープロファイルを更新
            await updateUserFamilyId(groupId)

            // リスナーを開始
            listenToFamilyGroup(groupId: groupId)
        } catch {
            errorMessage = "家族グループの作成に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func joinFamilyGroup(inviteCode: String) async {
        isLoading = true
        errorMessage = nil

        guard let userId = Auth.auth().currentUser?.uid,
              let userEmail = Auth.auth().currentUser?.email,
              let userName = Auth.auth().currentUser?.displayName else {
            errorMessage = "ユーザー情報の取得に失敗しました"
            isLoading = false
            return
        }

        do {
            // 招待コードでグループを検索
            let snapshot = try await db.collection("families")
                .whereField("inviteCode", isEqualTo: inviteCode.uppercased())
                .limit(to: 1)
                .getDocuments()

            guard let document = snapshot.documents.first else {
                errorMessage = "招待コードが無効です"
                isLoading = false
                return
            }

            let groupId = document.documentID
            let group = try document.data(as: FamilyGroup.self)

            // メンバー数の確認
            let membersCount = try await db.collection("families").document(groupId)
                .collection("members").getDocuments().count

            if membersCount >= group.maxMembers {
                errorMessage = "このグループは最大人数に達しています"
                isLoading = false
                return
            }

            // 既にメンバーかチェック
            let memberDoc = try await db.collection("families").document(groupId)
                .collection("members").document(userId).getDocument()

            if memberDoc.exists {
                errorMessage = "既にこのグループのメンバーです"
                isLoading = false
                return
            }

            // メンバーとして追加
            let newMember = FamilyMember(
                userId: userId,
                name: userName,
                email: userEmail,
                role: .member
            )

            try await db.collection("families").document(groupId)
                .collection("members").document(userId).setData(from: newMember)

            // ユーザープロファイルを更新
            await updateUserFamilyId(groupId)

            // リスナーを開始
            listenToFamilyGroup(groupId: groupId)
        } catch {
            errorMessage = "グループへの参加に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func listenToFamilyGroup(groupId: String) {
        // グループ情報のリスナー
        groupListener = db.collection("families").document(groupId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let document = documentSnapshot else {
                    self?.errorMessage = "グループ情報の取得に失敗: \(error?.localizedDescription ?? "Unknown error")"
                    return
                }

                do {
                    self?.familyGroup = try document.data(as: FamilyGroup.self)
                } catch {
                    self?.errorMessage = "グループデータの解析に失敗: \(error.localizedDescription)"
                }
            }

        // メンバーリストのリスナー
        membersListener = db.collection("families").document(groupId)
            .collection("members")
            .order(by: "joinedAt")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    self?.errorMessage = "メンバー情報の取得に失敗: \(error?.localizedDescription ?? "Unknown error")"
                    return
                }

                self?.familyMembers = documents.compactMap { doc in
                    try? doc.data(as: FamilyMember.self)
                }
            }
    }

    func removeMember(memberId: String) async {
        guard let groupId = familyGroup?.id else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await db.collection("families").document(groupId)
                .collection("members").document(memberId).delete()

            // ユーザーのfamilyIdをクリア
            try await db.collection("users").document(memberId)
                .updateData(["familyId": FieldValue.delete()])
        } catch {
            errorMessage = "メンバーの削除に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func updateMemberRole(memberId: String, newRole: MemberRole) async {
        guard let groupId = familyGroup?.id else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await db.collection("families").document(groupId)
                .collection("members").document(memberId)
                .updateData(["role": newRole.rawValue])
        } catch {
            errorMessage = "権限の変更に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func regenerateInviteCode() async {
        guard let groupId = familyGroup?.id else { return }

        isLoading = true
        errorMessage = nil

        let newCode = FamilyGroup.generateInviteCode()

        do {
            try await db.collection("families").document(groupId)
                .updateData([
                    "inviteCode": newCode,
                    "updatedAt": Date()
                ])
        } catch {
            errorMessage = "招待コードの更新に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func leaveFamilyGroup() async {
        guard let groupId = familyGroup?.id,
              let userId = Auth.auth().currentUser?.uid else { return }

        isLoading = true
        errorMessage = nil

        do {
            // メンバーから削除
            try await db.collection("families").document(groupId)
                .collection("members").document(userId).delete()

            // ユーザーのfamilyIdをクリア
            try await db.collection("users").document(userId)
                .updateData(["familyId": FieldValue.delete()])

            // リスナーを停止
            groupListener?.remove()
            membersListener?.remove()

            familyGroup = nil
            familyMembers = []
        } catch {
            errorMessage = "グループからの退出に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func updateUserFamilyId(_ familyId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            try await db.collection("users").document(userId)
                .updateData([
                    "familyId": familyId,
                    "updatedAt": Date()
                ])
        } catch {
            print("ユーザープロファイルの更新に失敗: \(error)")
        }
    }
}