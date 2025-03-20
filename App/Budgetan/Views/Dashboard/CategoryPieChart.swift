import SwiftUI

struct CategoryPieChart: View {
    let expenses: [Expense]

    var body: some View {
        let categoryTotals = Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        let total = categoryTotals.values.reduce(0, +)
        let slices = categoryTotals.map { ($0.key, $0.value / total) }
        
        return VStack {
            Text("Expense Categories")
                .font(.headline)
            GeometryReader { geometry in
                ZStack {
                    ForEach(slices.indices, id: \.self) { index in
                        PieSlice(startAngle: angle(for: index, in: slices), endAngle: angle(for: index + 1, in: slices))
                            .fill(sliceColor(for: slices[index].0))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.width)
            }
            .frame(maxWidth: 300)
            
            // Legend
            HStack(spacing: 20) {
                ForEach(slices, id: \.0) { slice in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(sliceColor(for: slice.0))
                            .frame(width: 10, height: 10)
                        Text(slice.0)
                            .font(.caption)
                    }
                }
            }
            .padding(.top, 10)
        }
    }

    private func angle(for index: Int, in slices: [(String, Double)]) -> Angle {
        let total = slices[..<index].reduce(0) { $0 + $1.1 }
        return .degrees(total * 360)
    }

    private func sliceColor(for category: String) -> Color {
        switch category {
        case "Living Costs": return .blue
        case "Entertainment": return .purple
        case "Unexpected": return .red
        case "Personal Care": return .green
        case "Other": return .gray
        default: return .gray
        }
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}
