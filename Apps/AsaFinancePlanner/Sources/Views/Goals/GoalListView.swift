import SwiftUI
import AsaUIKit
import AsaFinancePlannerKit

struct GoalListView: View {
    @State var viewModel: GoalViewModel
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if let plan = viewModel.plan, !plan.goals.isEmpty {
                    goalList(plan.goals)
                } else {
                    emptyState
                }
            }
            .navigationTitle("目標")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.resetForm()
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                GoalFormSheet(viewModel: viewModel, isEditing: false)
            }
            .onAppear { viewModel.loadGoals() }
            .refreshable { viewModel.loadGoals() }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }

    private func goalList(_ goals: [FinancialGoal]) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                GoalProgressChart(goals: goals)
                    .padding(.bottom, 8)

                ForEach(goals.sorted { $0.priority > $1.priority }, id: \.id) { goal in
                    NavigationLink {
                        GoalDetailView(viewModel: viewModel, goal: goal)
                    } label: {
                        GoalSummaryCard(goal: goal)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundStyle(AsaColors.mutedSage.opacity(0.5))
            Text("目標を設定して資産計画を始めましょう")
                .font(.subheadline)
                .foregroundStyle(AsaColors.mutedSage)
            AsaButton(title: "最初の目標を追加") {
                viewModel.resetForm()
                showAddSheet = true
            }
        }
        .padding()
    }
}
