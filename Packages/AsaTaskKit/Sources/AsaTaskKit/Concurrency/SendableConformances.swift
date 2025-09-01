import Foundation

// MARK: - Concurrency bridging for SwiftData models
// These models are reference types managed via SwiftData. When returned from
// the TaskDataService actor to a @MainActor view model, Swift's strict
// concurrency checks require Sendable conformance. We use @unchecked here
// because SwiftData manages thread-safety of the underlying storage and the
// app mutates them only from the main actor via the service.

extension Task: @unchecked Sendable {}
extension TaskColumn: @unchecked Sendable {}
extension TaskBoard: @unchecked Sendable {}
extension TaskStatus: @unchecked Sendable {}
