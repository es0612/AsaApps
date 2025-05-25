import SwiftUI

class MemoManager: ObservableObject {
    @Published var memos: [Memo] = [] {
        didSet {
            saveMemos()
        }
    }
    
    private let userDefaultsKey = "AsaMemoData"

    init() {
        loadMemos()
    }

    private func loadMemos() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedMemos = try? JSONDecoder().decode([Memo].self, from: data) {
            self.memos = savedMemos
        }
    }

    private func saveMemos() {
        if let encoded = try? JSONEncoder().encode(memos) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func addMemo(content: String) {
        let newMemo = Memo(content: content, createdAt: Date())
        memos.append(newMemo)
    }
}
