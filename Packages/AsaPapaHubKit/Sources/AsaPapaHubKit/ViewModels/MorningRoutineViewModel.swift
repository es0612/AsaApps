import Foundation

// MARK: - 朝活ルーティンViewModel

@MainActor
@Observable
public final class MorningRoutineViewModel {
    // MARK: - Properties

    public var routine: MorningRoutine?
    public var currentItemIndex: Int = 0
    public var isRoutineActive: Bool = false
    public var elapsedSeconds: Int = 0
    public var isLoading = false
    public var error: PapaHubError?

    @ObservationIgnored
    nonisolated(unsafe) var timer: Timer?

    private let routineService: MorningRoutineServiceProtocol
    private let scoreCalculator: ScoreCalculatorProtocol

    // MARK: - Init

    public init(
        routineService: MorningRoutineServiceProtocol,
        scoreCalculator: ScoreCalculatorProtocol
    ) {
        self.routineService = routineService
        self.scoreCalculator = scoreCalculator
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Methods

    public func loadRoutine() async {
        isLoading = true
        do {
            routine = try await routineService.fetchRoutine(for: Date())
            if routine == nil {
                routine = try await routineService.createDefaultRoutine(for: Date())
            }
        } catch let e as PapaHubError {
            error = e
        } catch {
            self.error = .fetchFailed(error.localizedDescription)
        }
        isLoading = false
    }

    public func startRoutine() async {
        guard let routine else { return }
        do {
            try await routineService.startRoutine(routine)
            isRoutineActive = true
            elapsedSeconds = 0
            startTimer()
        } catch let e as PapaHubError {
            error = e
        } catch {
            self.error = .fetchFailed(error.localizedDescription)
        }
    }

    public func completeCurrentItem() async {
        guard let routine else { return }
        let sortedItems = routine.items.sorted { $0.order < $1.order }
        guard currentItemIndex < sortedItems.count else { return }
        do {
            try await routineService.completeItem(sortedItems[currentItemIndex])
            advanceToNextItem()
        } catch {
            self.error = .saveFailed(error.localizedDescription)
        }
    }

    public func skipCurrentItem() async {
        guard let routine else { return }
        let sortedItems = routine.items.sorted { $0.order < $1.order }
        guard currentItemIndex < sortedItems.count else { return }
        do {
            try await routineService.skipItem(sortedItems[currentItemIndex])
            advanceToNextItem()
        } catch {
            self.error = .saveFailed(error.localizedDescription)
        }
    }

    public func finishRoutine() async {
        guard let routine else { return }
        do {
            try await routineService.finishRoutine(routine)
            isRoutineActive = false
            stopTimer()
            routine.totalScore = scoreCalculator.calculateMorningScore(routine: routine)
        } catch {
            self.error = .saveFailed(error.localizedDescription)
        }
    }

    // MARK: - Private

    private func advanceToNextItem() {
        guard let routine else { return }
        let sortedItems = routine.items.sorted { $0.order < $1.order }
        currentItemIndex += 1
        if currentItemIndex < sortedItems.count {
            sortedItems[currentItemIndex].status = .inProgress
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedSeconds += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
