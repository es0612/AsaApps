//
//  FamilyMembersView.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import SwiftUI
import SwiftData

struct FamilyMembersView: View {
    var viewModel: FamilyAlbumViewModel
    @State private var showingCreateMember = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.familyMembers.isEmpty {
                    EmptyFamilyMembersView()
                } else {
                    FamilyMembersList(members: viewModel.familyMembers, viewModel: viewModel)
                }
            }
            .navigationTitle("家族")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateMember = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color("AsaCoffeeBrown"))
                    }
                }
            }
            .sheet(isPresented: $showingCreateMember) {
                CreateFamilyMemberView(viewModel: viewModel)
            }
        }
    }
}

struct FamilyMembersList: View {
    let members: [FamilyMember]
    var viewModel: FamilyAlbumViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(members) { member in
                    NavigationLink(destination: FamilyMemberDetailView(member: member, viewModel: viewModel)) {
                        FamilyMemberCard(member: member)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

struct FamilyMemberCard: View {
    let member: FamilyMember
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // アバター
                ZStack {
                    Circle()
                        .fill(Color(member.color).opacity(0.8))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: member.relationshipIcon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // 情報
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color("AsaDarkSlate"))
                    
                    Text(member.relationship)
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMocha"))
                    
                    if let age = member.age {
                        Text("\(age)歳")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                }
                
                Spacer()
                
                // 統計
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(member.photoCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    
                    Text("枚の写真")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                }
            }
            
            // 説明
            if let description = member.profileDescription, !description.isEmpty {
                HStack {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color("AsaMocha"))
                        .lineLimit(2)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color("AsaDarkSlate").opacity(0.1), radius: 4)
    }
}

struct EmptyFamilyMembersView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 64))
                .foregroundColor(Color("AsaMutedSage"))
            
            VStack(spacing: 8) {
                Text("家族メンバーが登録されていません")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaDarkSlate"))
                
                Text("右上の「+」ボタンから\n家族メンバーを登録しましょう")
                    .font(.body)
                    .foregroundColor(Color("AsaMocha"))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AsaSoftCream").opacity(0.3))
    }
}

struct CreateFamilyMemberView: View {
    var viewModel: FamilyAlbumViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var nickname = ""
    @State private var relationship = "家族"
    @State private var birthDate = Date()
    @State private var hasBirthDate = false
    @State private var description = ""
    @State private var selectedColor = "AsaMutedSage"
    
    private let relationships = ["父", "母", "子供", "おじいちゃん", "おばあちゃん", "ペット", "家族"]
    private let colors = ["AsaCoffeeBrown", "AsaMocha", "AsaSoftCream", "AsaDarkSlate", "AsaMutedSage"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本情報").foregroundColor(Color("AsaCoffeeBrown"))) {
                    TextField("名前", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("ニックネーム（オプション）", text: $nickname)
                        .textInputAutocapitalization(.words)
                    
                    Picker("続柄", selection: $relationship) {
                        ForEach(relationships, id: \.self) { rel in
                            Text(rel).tag(rel)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("詳細情報").foregroundColor(Color("AsaCoffeeBrown"))) {
                    Toggle("誕生日を設定", isOn: $hasBirthDate)
                        .tint(Color("AsaCoffeeBrown"))
                    
                    if hasBirthDate {
                        DatePicker("誕生日", selection: $birthDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    
                    TextField("説明（オプション）", text: $description, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section(header: Text("表示色").foregroundColor(Color("AsaCoffeeBrown"))) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(colors, id: \.self) { colorName in
                            Button {
                                selectedColor = colorName
                            } label: {
                                Circle()
                                    .fill(Color(colorName))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == colorName ? Color("AsaDarkSlate") : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button("メンバーを作成") {
                        Task {
                            await viewModel.createFamilyMember(
                                name: name,
                                nickname: nickname.isEmpty ? nil : nickname,
                                relationship: relationship,
                                birthDate: hasBirthDate ? birthDate : nil,
                                description: description.isEmpty ? nil : description,
                                color: selectedColor
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? Color("AsaMutedSage") : Color("AsaCoffeeBrown"))
                }
            }
            .navigationTitle("新しいメンバー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaMocha"))
                }
            }
        }
    }
}

struct FamilyMemberDetailView: View {
    let member: FamilyMember
    var viewModel: FamilyAlbumViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // プロフィールヘッダー
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(member.color).opacity(0.8))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: member.relationshipIcon)
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text(member.fullDisplayName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaDarkSlate"))
                        
                        Text(member.relationship)
                            .font(.title3)
                            .foregroundColor(Color("AsaMocha"))
                        
                        if let age = member.age {
                            Text(member.ageString)
                                .font(.subheadline)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                    }
                    
                    if let description = member.profileDescription {
                        Text(description)
                            .font(.body)
                            .foregroundColor(Color("AsaDarkSlate"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 32)
                
                // 統計情報
                HStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("\(member.photoCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        
                        Text("写真")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    if member.birthDate != nil {
                        VStack(spacing: 8) {
                            Text(member.formattedBirthDate)
                                .font(.headline)
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            Text("誕生日")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                    }
                }
                
                // 最近の写真
                if !member.recentPhotos.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("最近の写真")
                            .font(.headline)
                            .foregroundColor(Color("AsaDarkSlate"))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 8) {
                                ForEach(member.recentPhotos) { photo in
                                    NavigationLink(destination: PhotoDetailView(photo: photo, viewModel: viewModel)) {
                                        PhotoThumbnailView(photo: photo, viewModel: viewModel)
                                            .frame(width: 120, height: 120)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer(minLength: 32)
            }
        }
        .background(Color("AsaSoftCream").opacity(0.3))
        .navigationTitle(member.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    FamilyMembersView(viewModel: FamilyAlbumViewModel())
        .modelContainer(for: [Album.self, Photo.self, Comment.self, FamilyMember.self])
}
