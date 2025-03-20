import Foundation

class DashboardService {
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func fetchMonthlyExpenses(year: Int, month: Int, completion: @escaping (Result<[Expense], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.expenseBaseURL)/get_monthly_expense?year=\(year)&month=\(month)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid expense URL"])))
            return
        }

        authService.makeAuthenticatedRequest(url: url, method: "GET", body: nil) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])))
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

    func fetchMonthlyIncomes(year: Int, month: Int, completion: @escaping (Result<[Income], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.incomeBaseURL)/get_monthly_income?year=\(year)&month=\(month)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid income URL"])))
            return
        }

        authService.makeAuthenticatedRequest(url: url, method: "GET", body: nil) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])))
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

struct ExpenseResponse: Codable {
    let expenses: [Expense]
}

struct IncomeResponse: Codable {
    let incomes: [Income]
}
