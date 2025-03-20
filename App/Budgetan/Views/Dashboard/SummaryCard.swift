import SwiftUI

struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(String(format: "$%.2f", amount))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(width: 100, height: 80)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
