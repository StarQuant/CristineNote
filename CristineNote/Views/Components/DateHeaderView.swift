import SwiftUI

struct DateHeaderView: View {
    let date: String

    var body: some View {
        Text(date)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.vertical, 4)
    }
}