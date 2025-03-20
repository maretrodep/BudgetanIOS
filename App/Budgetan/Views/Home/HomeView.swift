import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            ExpenseView()
                .tabItem {
                    Label("Expense", systemImage: "minus.circle")
                }
            IncomeView()
                .tabItem {
                    Label("Income", systemImage: "plus.circle")
                }
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthService())
    }
}
