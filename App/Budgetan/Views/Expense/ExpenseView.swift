import SwiftUI

struct ExpenseView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedDate = Date()
    @State private var expenses: [Expense] = []
    @State private var selectedExpenseIds: Set<Int> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingAddExpense = false

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
                    fetchExpenses()
                }

                // Expense list
                if isLoading {
                    ProgressView("Loading...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else if expenses.isEmpty {
                    Text("No expenses for \(dateFormatter.string(from: selectedDate))")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(expenses) { expense in
                            ExpenseRow(expense: expense, isSelected: selectedExpenseIds.contains(expense.id))
                                .onTapGesture {
                                    if selectedExpenseIds.contains(expense.id) {
                                        selectedExpenseIds.remove(expense.id)
                                    } else {
                                        selectedExpenseIds.insert(expense.id)
                                    }
                                }
                        }
                    }
                }

                Spacer()

                // Delete button (visible when expenses are selected)
                if !selectedExpenseIds.isEmpty {
                    Button(action: {
                        deleteExpenses()
                    }) {
                        Text("Delete Selected (\(selectedExpenseIds.count))")
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
            .navigationTitle("Expenses")
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(onSave: {
                    fetchExpenses() // Refresh list after adding
                })
                    .environmentObject(authService)
            }
            .onAppear {
                fetchExpenses()
            }
        }
    }

    // Fetch expenses for the selected month
    private func fetchExpenses() {
        isLoading = true
        errorMessage = nil
        selectedExpenseIds.removeAll()

        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)

        guard let url = URL(string: "\(Constants.expenseBaseURL)/get_monthly_expense?year=\(year)&month=\(month)") else {
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
                    errorMessage = "Failed to fetch expenses"
                    return
                }

                do {
                    let result = try JSONDecoder().decode(ExpenseResponse.self, from: data)
                    expenses = result.expenses
                } catch {
                    errorMessage = "Error decoding data: \(error.localizedDescription)"
                }
            }
        }
    }

    // Delete selected expenses
    private func deleteExpenses() {
        guard !selectedExpenseIds.isEmpty,
              let url = URL(string: "\(Constants.expenseBaseURL)/delete_expenses") else {
            errorMessage = "Invalid request"
            return
        }

        let body: [String: [Int]] = ["expense_ids": Array(selectedExpenseIds)]
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
                    errorMessage = "Failed to delete expenses"
                    return
                }

                // Successfully deleted, refresh the list
                fetchExpenses()
            }
        }
    }
}

// Expense row view
struct ExpenseRow: View {
    let expense: Expense
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(expense.category) - $\(String(format: "%.2f", expense.amount))")
                    .font(.headline)
                Text("Status: \(expense.status) | Mood: \(expense.mood)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if let note = expense.note, !note.isEmpty {
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
}

// Add expense view
struct AddExpenseView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var amount = ""
    @State private var category = "Living Costs"
    @State private var priority = "Essential"
    @State private var status = "Pending"
    @State private var mood = "Happy"
    @State private var note = ""
    @State private var errorMessage: String?
    let onSave: () -> Void

    private let categories = ["Living Costs", "Entertainment", "Unexpected", "Personal Care", "Other"]
    private let priorities = ["Essential", "Optional"]
    private let statuses = ["Pending", "Paid"]
    private let moods = ["Happy", "Sad"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { Text($0) }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(statuses, id: \.self) { Text($0) }
                    }
                    Picker("Mood", selection: $mood) {
                        ForEach(moods, id: \.self) { Text($0) }
                    }
                    TextField("Note (optional)", text: $note)
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addExpense() }
                }
            }
        }
    }

    private func addExpense() {
        guard let amountValue = Double(amount), amountValue > 0,
              let url = URL(string: "\(Constants.expenseBaseURL)/add_expense") else {
            errorMessage = "Invalid amount or URL"
            return
        }

        let body: [String: Any] = [
            "amount": amountValue,
            "category": category,
            "priority": priority,
            "status": status,
            "mood": mood,
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
                        errorMessage = "Failed to add expense"
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

struct ExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseView()
            .environmentObject(AuthService())
    }
}
