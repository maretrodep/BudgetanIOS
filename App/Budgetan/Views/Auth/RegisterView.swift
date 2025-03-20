import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var profileName = ""
    @State private var password = ""
    @State private var password_repeat = ""
    @State private var errorMessage: String?
    @State private var registrationSuccess = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Register for Budgetan")
                .font(.title)
                .fontWeight(.bold)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)

            TextField("Profile Name", text: $profileName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Password Repeat", text: $password_repeat)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            if registrationSuccess {
                Text("Registration successful! Please log in.")
                    .foregroundColor(.green)
            }

            Button("Register") {
                authService.register(email: email, profileName: profileName, password: password, password_repeat: password_repeat) { success, message in
                    if success {
                        registrationSuccess = true
                        errorMessage = nil
                    } else {
                        errorMessage = message
                        registrationSuccess = false
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
