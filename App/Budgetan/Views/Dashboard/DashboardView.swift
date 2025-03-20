import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedDate = Date()
    @State private var expenses: [Expense] = []
    @State private var incomes: [Income] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Month selector
                    DatePicker(
                        "Select Month",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .onChange(of: selectedDate) { _ in
                        fetchData()
                    }
                    .padding(.horizontal)

                    // Totals
                    VStack(spacing: 10) {
                        Text("Monthly Summary - \(dateFormatter.string(from: selectedDate))")
                            .font(.headline)
                        HStack(spacing: 20) {
                            SummaryCard(title: "Income", amount: totalIncome, color: .green)
                            SummaryCard(title: "Expenses", amount: totalExpenses, color: .red)
                            SummaryCard(title: "Pending", amount: pendingExpenses, color: .orange)
                        }
                    }
                    .padding(.horizontal)

                    // Category Pie Chart
                    if !isLoading && !expenses.isEmpty {
                        CategoryPieChart(expenses: expenses)
                            .frame(height: 300)
                            .padding()
                    } else if isLoading {
                        ProgressView("Loading...")
                    } else if let error = errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Dashboard")
            .background(Color(.systemBackground))
            .onAppear {
                fetchData()
            }
        }
    }

    // Computed properties for totals
    private var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var pendingExpenses: Double {
        expenses.filter { $0.status == "Pending" }.reduce(0) { $0 + $1.amount }
    }

    // Fetch data from backend
    private func fetchData() {
        isLoading = true
        errorMessage = nil

        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)

        fetchMonthlyExpenses(year: year, month: month) { expenseResult in
            fetchMonthlyIncomes(year: year, month: month) { incomeResult in
                DispatchQueue.main.async {
                    isLoading = false
                    switch (expenseResult, incomeResult) {
                    case (.success(let fetchedExpenses), .success(let fetchedIncomes)):
                        self.expenses = fetchedExpenses
                        self.incomes = fetchedIncomes
                    case (.failure(let error), _), (_, .failure(let error)):
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func fetchMonthlyExpenses(year: Int, month: Int, completion: @escaping (Result<[Expense], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.expenseBaseURL)/get_monthly_expense?year=\(year)&month=\(month)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        authService.makeAuthenticatedRequest(url: url, method: "GET", body: nil) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }

            do {
                let result = try JSONDecoder().decode(ExpenseResponse.self, from: data)
                completion(.success(result.expenses))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func fetchMonthlyIncomes(year: Int, month: Int, completion: @escaping (Result<[Income], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.incomeBaseURL)/get_monthly_income?year=\(year)&month=\(month)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        authService.makeAuthenticatedRequest(url: url, method: "GET", body: nil) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }

            do {
                let result = try JSONDecoder().decode(IncomeResponse.self, from: data)
                completion(.success(result.incomes))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AuthService())
    }
}
