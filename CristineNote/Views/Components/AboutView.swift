import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "app.badge")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("CristineNote")
                    .font(.title)
                    .fontWeight(.bold)

                Text(LocalizedString("version"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LocalizedText("app_description")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Text("© 2024 CristineNote")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle(LocalizedString("about"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}