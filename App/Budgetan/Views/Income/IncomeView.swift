import SwiftUI

struct IncomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedDate = Date()
    @State private var incomes: [Income] = []
    @State private var selectedIncomeIds: Set<Int> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingAddIncome = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var body: some View {
        NavigationView {
            VStack {
                // Month selector
                DatePicker(
                    "Select Month",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .padding(.horizontal)
                .onChange(of: selectedDate) { _ in
                    fetchIncomes()
                }

                // Income list
                if isLoading {
                    ProgressView("Loading...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else if incomes.isEmpty {
                    Text("No income for \(dateFormatter.string(from: selectedDate))")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(incomes) { income in
                            IncomeRow(income: income, isSelected: selectedIncomeIds.contains(income.id))
                                .onTapGesture {
                                    if selectedIncomeIds.contains(income.id) {
                                        selectedIncomeIds.remove(income.id)
                                    } else {
                                        selectedIncomeIds.insert(income.id)
                                    }
                                }
                        }
                    }
                }

                Spacer()

                // Delete button (visible when incomes are selected)
                if !selectedIncomeIds.isEmpty {
                    Button(action: {
                        deleteIncomes()
                    }) {
                        Text("Delete Selected (\(selectedIncomeIds.count))")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Income")
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddIncome = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddIncome) {
                AddIncomeView(onSave: {
                    fetchIncomes() // Refresh list after adding
                })
                    .environmentObject(authService)
            }
            .onAppear {
                fetchIncomes()
            }
        }
    }

    // Fetch incomes for the selected month
    private func fetchIncomes() {
        isLoading = true
        errorMessage = nil
        selectedIncomeIds.removeAll()

        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)

        guard let url = URL(string: "\(Constants.incomeBaseURL)/get_monthly_income?year=\(year)&month=\(month)") else {
            isLoading = false
            errorMessage = "Invalid URL"
            return
        }

        authService.makeAuthenticatedRequest(url: url, method: "GET", body: nil) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                      let data = data else {
                    errorMessage = "Failed to fetch income"
                    return
                }

                do {
                    let result = try JSONDecoder().decode(IncomeResponse.self, from: data)
                    incomes = result.incomes
                } catch {
                    errorMessage = "Error decoding data: \(error.localizedDescription)"
                }
            }
        }
    }

    // Delete selected incomes
    private func deleteIncomes() {
        guard !selectedIncomeIds.isEmpty,
              let url = URL(string: "\(Constants.incomeBaseURL)/delete_incomes") else {
            errorMessage = "Invalid request"
            return
        }

        let body: [String: [Int]] = ["income_ids": Array(selectedIncomeIds)]
        isLoading = true

        authService.makeAuthenticatedRequest(url: url, method: "DELETE", body: body) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode),
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                      let _ = json["message"] else {
                    errorMessage = "Failed to delete incomes"
                    return
                }

                // Successfully deleted, refresh the list
                fetchIncomes()
            }
        }
    }
}

// Income row view
// Income row view
struct IncomeRow: View {
    let income: Income
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("$\(String(format: "%.2f", income.amount))")
                    .font(.headline)
                Text("Date: \(formattedDate(income.time))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if let note = income.note, !note.isEmpty {
                    Text("Note: \(note)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 5)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter.string(from: date)
    }
}

// Add income view
struct AddIncomeView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var amount = ""
    @State private var note = ""
    @State private var errorMessage: String?
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Income Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Note (optional)", text: $note)
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Add Income")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addIncome() }
                }
            }
        }
    }

    private func addIncome() {
        guard let amountValue = Double(amount), amountValue > 0,
              let url = URL(string: "\(Constants.incomeBaseURL)/add_income") else {
            errorMessage = "Invalid amount or URL"
            return
        }

        let body: [String: Any] = [
            "amount": amountValue,
            "note": note.isEmpty ? nil : note
        ].compactMapValues { $0 }

        authService.makeAuthenticatedRequest(url: url, method: "POST", body: body) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                       let message = json["message"] {
                        errorMessage = message
                    } else {
                        errorMessage = "Failed to add income"
                    }
                    return
                }

                // Success, dismiss and refresh parent view
                dismiss()
                onSave()
            }
        }
    }
}

struct IncomeView_Previews: PreviewProvider {
    static var previews: some View {
        IncomeView()
            .environmentObject(AuthService())
    }
}
