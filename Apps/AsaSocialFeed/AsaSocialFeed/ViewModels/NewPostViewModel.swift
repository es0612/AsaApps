import Foundation

@MainActor
@Observable
final class NewPostViewModel {
    // MARK: - State

    var content: String = ""
    var isSubmitting = false

    // MARK: - Computed Properties

    var canSubmit: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Methods

    func reset() {
        content = ""
        isSubmitting = false
    }
}
