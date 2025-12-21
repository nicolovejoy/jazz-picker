//
//  AuthStore.swift
//  JazzPicker
//

import AuthenticationServices
import Combine
import CryptoKit
import FirebaseAuth
import Foundation

class AuthStore: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var isLoading = true
    @Published private(set) var error: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var didStart = false

    init() {
        // Don't call Firebase here — it may not be configured yet
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    /// Call this after FirebaseApp.configure() has run
    func start() {
        guard !didStart else { return }
        didStart = true

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isLoading = false
        }
    }

    // MARK: - Apple Sign In

    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)
    }

    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            handleAuthorization(authorization)
        case .failure(let error):
            self.error = error.localizedDescription
        }
    }

    private func handleAuthorization(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            error = "Invalid credential type"
            return
        }

        guard let nonce = currentNonce else {
            error = "No nonce available"
            return
        }

        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            error = "Unable to fetch identity token"
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        isLoading = true
        error = nil

        Auth.auth().signIn(with: credential) { [weak self] _, error in
            self?.isLoading = false
            if let error = error {
                self?.error = error.localizedDescription
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearError() {
        error = nil
    }

    // MARK: - Nonce Generation

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
