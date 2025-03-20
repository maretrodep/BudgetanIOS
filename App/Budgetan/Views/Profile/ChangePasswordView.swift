import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var authService: AuthService
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var newPasswordRepeat: String = ""
    @State private var message: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            SecureField("Current Password", text: $currentPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            SecureField("New Password", text: $newPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            SecureField("Confirm New Password", text: $newPasswordRepeat)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Button(action: {
                changePassword()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Change Password")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading)
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Change Password")
    }
    
    private func changePassword() {
        // Local validation
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !newPasswordRepeat.isEmpty else {
            message = "All fields are required."
            return
        }
        
        guard newPassword == newPasswordRepeat else {
            message = "New passwords do not match."
            return
        }
        
        isLoading = true
        message = ""
        
        authService.changePassword(currentPassword: currentPassword,
                                   newPassword: newPassword,
                                   newPasswordRepeat: newPasswordRepeat) { success, errorMessage in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.message = "Password changed successfully."
                    // Optionally, clear the fields here
                    self.currentPassword = ""
                    self.newPassword = ""
                    self.newPasswordRepeat = ""
                } else {
                    self.message = errorMessage ?? "An error occurred."
                }
            }
        }
    }
}

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChangePasswordView()
                .environmentObject(AuthService())
        }
    }
}
