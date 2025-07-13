import SwiftUI

struct RaceUpgradePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingUpgradeView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: Constants.Spacing.large) {
                // アイコン
                Image(systemName: "flag.checkered")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                VStack(spacing: Constants.Spacing.medium) {
                    Text("レース記録制限")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("無料プランでは30件までのレース記録が可能です。\n無制限でレース記録を追加するには、プレミアムプランにアップグレードしてください。")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: Constants.Spacing.medium) {
                    Text("プレミアムプランの特典")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("無制限のレース記録")
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("無制限のバイク登録")
                            Spacer()
                        }
                        
                        // 仮リリースでは広告なしのため一時的にコメントアウト
                        // HStack {
                        //     Image(systemName: "checkmark.circle.fill")
                        //         .foregroundColor(.green)
                        //     Text("広告なし")
                        //     Spacer()
                        // }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("CSVエクスポート機能")
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("全機能の利用")
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Constants.Colors.surfaceFallback)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                }
                
                Spacer()
                
                VStack(spacing: Constants.Spacing.medium) {
                    Button(action: {
                        showingUpgradeView = true
                    }) {
                        Text("プレミアムプランにアップグレード")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange, .red]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Constants.CornerRadius.medium))
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("後で")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(Constants.Spacing.large)
            .navigationTitle("アップグレード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingUpgradeView) {
            PremiumUpgradeView()
        }
    }
}

#Preview {
    RaceUpgradePromptView()
}