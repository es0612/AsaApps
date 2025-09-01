import Foundation

// Export Sendable conformance for UI enums used across actor boundaries.
// Marked as @unchecked since the conformance is added outside the file
// where the enum is declared.
extension TaskPriority: @unchecked Sendable {}
