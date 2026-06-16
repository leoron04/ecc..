import SwiftUI

struct OnlineIndicator: View {
    let isOnline: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(isOnline ? Color.green : Color.orange)
                .frame(width: 10, height: 10)

            Text(isOnline ? "Online" : "Offline")
                .font(.subheadline.weight(.medium))

            Spacer()

            Text(isOnline ? "Hub raggiungibile" : "Uso cache locale")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

