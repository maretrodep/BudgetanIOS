import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Budgetan")
                .font(.title)
                .fontWeight(.bold)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Button("Login") {
                authService.login(email: email, password: password) { success, message in
                    if !success {
                        errorMessage = message
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            NavigationLink("Don't have an account? Register", destination: RegistrationView())
        }
        .padding()
    }
}
