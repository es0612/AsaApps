import SwiftUI

struct ContentView: View {
    @State private var tasks: [Task] = []
    @State private var newTaskTitle: String = ""
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                    .opacity(colorScheme == .dark ? 0.9 : 0.1)
                    .ignoresSafeArea()
                Color(colorScheme == .dark ? "AsaSoftCream" : "AsaDarkSlate")
                    .opacity(colorScheme == .dark ? 0.2 : 0.8)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("AsaToDo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                    // タスク入力欄と追加ボタン
                    HStack {
                        TextField("新しいタスクを入力", text: $newTaskTitle)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .accentColor(Color("AsaCoffeeBrown"))
                            .background(Color("AsaSoftCream").opacity(colorScheme == .dark ? 0.4 : 0.2))
                            .cornerRadius(8)

                        Button(action: addTask) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color("AsaMocha"))
                                .font(.title2)
                        }
                        .disabled(newTaskTitle.isEmpty)
                    }
                    .padding(.horizontal)

                    // タスクリスト
                    List {
                        ForEach(tasks) { task in
                            Text(task.title)
                                .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))
                        }
                        .onDelete(perform: deleteTasks)
                    }
                    .background(
                        Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                            .opacity(colorScheme == .dark ? 0.9 : 0.1)
                    )

                    Spacer()
                }
                .padding(.top)
                .navigationTitle("ToDo リスト")
                .toolbar {
                    EditButton()
                        .foregroundColor(Color("AsaMocha"))
                }
            }
        }
    }

    // タスク追加
    private func addTask() {
        guard !newTaskTitle.isEmpty else { return }
        tasks.append(Task(title: newTaskTitle))
        newTaskTitle = ""
    }

    // タスク削除
    private func deleteTasks(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}
