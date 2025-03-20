import Foundation
import SwiftUI

class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    private let keychainService = KeychainService()

    init() {
        // Check login status when the app starts
        checkAuthenticationStatus()
    }

    // MARK: - Public Methods

    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(Constants.authBaseURL)/login") else {
            completion(false, "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                DispatchQueue.main.async {
                    completion(false, "Invalid response")
                }
                return
            }

            switch httpResponse.statusCode {
            case 200:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let accessToken = json["access_token"],
                   let refreshToken = json["refresh_token"] {
                    self.keychainService.saveAccessToken(accessToken)
                    self.keychainService.saveRefreshToken(refreshToken)
                    DispatchQueue.main.async {
                        self.isAuthenticated = true
                        completion(true, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false, "Invalid response data")
                    }
                }
            case 400, 401:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let message = json["message"] {
                    DispatchQueue.main.async {
                        completion(false, message)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false, "Login failed")
                    }
                }
            default:
                DispatchQueue.main.async {
                    completion(false, "Unexpected error")
                }
            }
        }.resume()
    }

    func register(email: String, profileName: String, password: String, password_repeat: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(Constants.authBaseURL)/register") else {
            completion(false, "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["email": email, "profile_name": profileName, "password": password, "password_repeat": password_repeat]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(false, "Invalid response")
                }
                return
            }

            if httpResponse.statusCode == 201 {
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } else if let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                      let message = json["message"] {
                DispatchQueue.main.async {
                    completion(false, message)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, "Registration failed")
                }
            }
        }.resume()
    }

    func refreshToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = keychainService.getRefreshToken(),
              let url = URL(string: "\(Constants.authBaseURL)/refresh") else {
            logout()
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.logout()
                    completion(false)
                }
                return
            }

            if httpResponse.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let accessToken = json["access_token"] {
                self.keychainService.saveAccessToken(accessToken)
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                    self.logout()
                    completion(false)
                }
            }
        }.resume()
    }

    func changePassword(currentPassword: String, newPassword: String, newPasswordRepeat: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(Constants.authBaseURL)/change_password") else {
            completion(false, "Invalid URL")
            return
        }

        makeAuthenticatedRequest(url: url, method: "POST", body: [
            "current_password": currentPassword,
            "new_password": newPassword,
            "new_password_repeat": newPasswordRepeat
        ]) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                DispatchQueue.main.async {
                    completion(false, "Invalid response")
                }
                return
            }

            if httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                      let message = json["message"] {
                DispatchQueue.main.async {
                    completion(false, message)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, "Password change failed")
                }
            }
        }
    }

    func logout() {
        keychainService.clearTokens()
        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
    }

    func checkAndRefreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        guard isAuthenticated else {
            completion(true) // No action needed if not authenticated
            return
        }

        if let accessToken = keychainService.getAccessToken(),
           let expiration = getExpirationFromToken(accessToken),
           expiration < Date().addingTimeInterval(5 * 60) {
            refreshToken { success in
                if !success {
                    self.logout()
                }
                completion(success)
            }
        } else {
            completion(true) // Token is either valid or missing (no refresh needed)
        }
    }

    // MARK: - Private Methods

    private func checkAuthenticationStatus() {
        if let accessToken = keychainService.getAccessToken(),
           let expiration = getExpirationFromToken(accessToken) {
            let fiveMinutesFromNow = Date().addingTimeInterval(5 * 60)
            if expiration > fiveMinutesFromNow {
                isAuthenticated = true
            } else {
                refreshToken { success in
                    DispatchQueue.main.async {
                        self.isAuthenticated = success
                    }
                }
            }
        } else {
            isAuthenticated = false
        }
    }

    public func getExpirationFromToken(_ token: String) -> Date? {
        let components = token.split(separator: ".")
        guard components.count == 3,
              let data = Data(base64Encoded: String(components[1]), options: .ignoreUnknownCharacters),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: exp)
    }

    public func makeAuthenticatedRequest(url: URL, method: String, body: [String: Any]?, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let accessToken = keychainService.getAccessToken() else {
            logout()
            completion(nil, nil, NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]))
            return
        }

        if let expiration = getExpirationFromToken(accessToken), expiration > Date().addingTimeInterval(5 * 60) {
            performRequest(url: url, method: method, accessToken: accessToken, body: body, completion: completion)
        } else {
            refreshToken { success in
                if success, let newAccessToken = self.keychainService.getAccessToken() {
                    self.performRequest(url: url, method: method, accessToken: newAccessToken, body: body, completion: completion)
                } else {
                    self.logout()
                    completion(nil, nil, NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed"]))
                }
            }
        }
    }

    private func performRequest(url: URL, method: String, accessToken: String, body: [String: Any]?, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        URLSession.shared.dataTask(with: request, completionHandler: completion).resume()
    }
}
