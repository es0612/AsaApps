import SwiftUI

struct FamilyMemberManagerView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingAddMember = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.familyMembers, id: \.id) { member in
                    NavigationLink(destination: EditMemberView(viewModel: viewModel, member: member)) {
                        HStack {
                            Circle()
                                .fill(Color(member.color ?? "AsaCoffeeBrown"))
                                .frame(width: 20, height: 20)
                            
                            Text(member.name ?? "")
                                .font(.headline)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            Spacer()
                            
                            if member.isActive {
                                Text("アクティブ")
                                    .font(.caption)
                                    .foregroundColor(Color("AsaMutedSage"))
                            } else {
                                Text("非アクティブ")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationBarTitle("家族メンバー", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完了") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        isShowingAddMember = true
                    }
                }
            }
            .sheet(isPresented: $isShowingAddMember) {
                AddMemberView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.fetchFamilyMembers()
        }
    }
}

struct AddMemberView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var selectedColor = "AsaCoffeeBrown"
    
    private let colorOptions = [
        ("AsaCoffeeBrown", "コーヒーブラウン"),
        ("AsaSoftCream", "ソフトクリーム"),
        ("AsaMutedSage", "セージ"),
        ("AsaMocha", "モカ"),
        ("AsaDarkSlate", "スレート")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("名前", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("カラー")) {
                    ForEach(colorOptions, id: \.0) { option in
                        HStack {
                            Circle()
                                .fill(Color(option.0))
                                .frame(width: 20, height: 20)
                            
                            Text(option.1)
                                .foregroundColor(Color("AsaDarkSlate"))
                            
                            Spacer()
                            
                            if selectedColor == option.0 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedColor = option.0
                        }
                    }
                }
            }
            .navigationBarTitle("メンバー追加", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMember()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveMember() {
        DispatchQueue.main.async {
            self.viewModel.addFamilyMember(name: self.name, color: self.selectedColor)
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct EditMemberView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.presentationMode) var presentationMode
    
    let member: FamilyMember
    
    @State private var name = ""
    @State private var selectedColor = "AsaCoffeeBrown"
    @State private var isActive = true
    @State private var showingDeleteAlert = false
    
    private let colorOptions = [
        ("AsaCoffeeBrown", "コーヒーブラウン"),
        ("AsaSoftCream", "ソフトクリーム"),
        ("AsaMutedSage", "セージ"),
        ("AsaMocha", "モカ"),
        ("AsaDarkSlate", "スレート")
    ]
    
    var body: some View {
        Form {
            Section(header: Text("基本情報")) {
                TextField("名前", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Toggle("アクティブ", isOn: $isActive)
                    .toggleStyle(SwitchToggleStyle(tint: Color("AsaCoffeeBrown")))
            }
            
            Section(header: Text("カラー")) {
                ForEach(colorOptions, id: \.0) { option in
                    HStack {
                        Circle()
                            .fill(Color(option.0))
                            .frame(width: 20, height: 20)
                        
                        Text(option.1)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Spacer()
                        
                        if selectedColor == option.0 {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("AsaCoffeeBrown"))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedColor = option.0
                    }
                }
            }
            
            Section(header: Text("統計")) {
                HStack {
                    Text("関連イベント数")
                    Spacer()
                    Text("\(viewModel.eventsForMember(member).count)件")
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            
            Section {
                Button("削除") {
                    showingDeleteAlert = true
                }
                .foregroundColor(.red)
            }
        }
        .navigationBarTitle("メンバー編集", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveMember()
                }
                .disabled(name.isEmpty)
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("メンバーを削除"),
                message: Text("このメンバーと関連するイベントも削除されます。本当に削除しますか？"),
                primaryButton: .destructive(Text("削除")) {
                    deleteMember()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            loadMemberData()
        }
    }
    
    private func loadMemberData() {
        name = member.name ?? ""
        selectedColor = member.color ?? "AsaCoffeeBrown"
        isActive = member.isActive
    }
    
    private func saveMember() {
        DispatchQueue.main.async {
            self.viewModel.updateFamilyMember(self.member, name: self.name, color: self.selectedColor, isActive: self.isActive)
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func deleteMember() {
        DispatchQueue.main.async {
            self.viewModel.deleteFamilyMember(self.member)
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview("メンバー管理") {
    FamilyMemberManagerView(viewModel: CalendarViewModel.withManyEvents)
}

#Preview("メンバー追加") {
    AddMemberView(viewModel: CalendarViewModel.withManyEvents)
}