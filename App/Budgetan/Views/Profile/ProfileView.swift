import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var profileName: String = "Loading..."

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Profile picture placeholder
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .padding(.top, 40)
                
                // Display fetched profile name
                Text(profileName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Navigation link to Change Password
                NavigationLink(destination: ChangePasswordView().environmentObject(authService)) {
                    Text("Change Password")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                
                // Logout button
                Button(action: {
                    authService.logout()
                }) {
                    Text("Logout")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .onAppear {
                fetchProfileInfo()
            }
            .navigationTitle("Profile")
        }
    }
    
    private func fetchProfileInfo() {
        guard let url = URL(string: "\(Constants.authBaseURL)/profile_info") else {
            profileName = "Invalid URL"
            return
        }
        
        authService.makeAuthenticatedRequest(url: url, method: "GET", body: nil) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.profileName = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.profileName = "No data received"
                }
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(ProfileResponse.self, from: data)
                DispatchQueue.main.async {
                    self.profileName = decodedResponse.profile_name
                }
            } catch {
                DispatchQueue.main.async {
                    self.profileName = "Failed to decode data"
                }
            }
        }
    }
}

struct ProfileResponse: Codable {
    let profile_name: String
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthService())
    }
}
