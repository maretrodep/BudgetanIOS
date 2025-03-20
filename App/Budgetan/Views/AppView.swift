import SwiftUI

struct AppView: View {
    @StateObject var authService = AuthService()

    var body: some View {
        Group {
            if authService.isAuthenticated {
                HomeView()
                    .environmentObject(authService)
            } else {
                AuthView()
                    .environmentObject(authService)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            authService.checkAndRefreshTokenIfNeeded { success in
                // No additional action needed here; AuthService handles logout if refresh fails
                if !success {
                    print("Token refresh failed on foregrounding")
                }
            }
        }
        .onAppear {
            // Optionally check token on initial app launch
            authService.checkAndRefreshTokenIfNeeded { success in
                if !success {
                    print("Token refresh failed on app launch")
                }
            }
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}
