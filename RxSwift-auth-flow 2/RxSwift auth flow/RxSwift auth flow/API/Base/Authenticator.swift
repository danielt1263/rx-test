//
//  Authenticator.swift
//  RxSwift auth flow
//
//  Created by Anton Kovalenko on 03.01.2023.
//

import Moya
import RxCocoa
import RxSwift

protocol AuthenticatorType {
    func authenticate() -> Observable<Void>
    func checkForValidAuthTokenOrRefresh(forceRefresh: Bool) -> Observable<Void>
}

extension AuthenticatorType {
    func checkForValidAuthTokenOrRefresh(forceRefresh: Bool = false) -> Observable<Void> {
        return checkForValidAuthTokenOrRefresh(forceRefresh: forceRefresh)
    }
}

final class Authenticator<Provider: RxMoyaProviderType> where Provider.Target == NSTUAuthAPI {
    private let provider: Provider
    private let cookiesStorageProvider: CookiesStorageProviderType
    private let queue = DispatchQueue(label: "Autenticator.\(UUID().uuidString)")
    
    private var refreshInProgressObservable: Observable<Void>?
    
    init(
        provider: Provider,
        cookiesStorageProvider: CookiesStorageProviderType
    ) {
        self.provider = provider
        self.cookiesStorageProvider = cookiesStorageProvider
    }
    
    func checkForValidAuthTokenOrRefresh(forceRefresh: Bool = false) -> Observable<Void> {
        return queue.sync { [weak self] in
            self?.getCurrentTokenOrRefreshIfNeeded(forceRefresh: forceRefresh) ?? .just(())
        }
    }
    
    func authenticate() -> Observable<Void> {
        provider.request(.authenticate(credentials: .defaultDebugAccount))
            .map(LoginResponse.self)
            .map { loginResponse in
                guard loginResponse.login else {
                    throw AuthenticationError.loginRequired
                }
            }
            .asObservable()
    }
}

extension Authenticator: AuthenticatorType {
    
}

// MARK: - Helper methods
private extension Authenticator {
    func getCurrentTokenOrRefreshIfNeeded(forceRefresh: Bool = false) -> Observable<Void> {
        if let refreshInProgress = refreshInProgressObservable {
            return refreshInProgress
        }
        
        if cookiesStorageProvider.isHaveValidAuthToken && !forceRefresh {
            return .just(())
        }
        
        guard cookiesStorageProvider.isHaveValidRefreshToken else {
            return .error(AuthenticationError.loginRequired)
        }
        
        let refreshInProgress = provider.request(.refreshToken)
            .share()
            .map { response in
                guard response.statusCode != 401 else {
                    throw AuthenticationError.loginRequired
                }
                return response
            }
            .map(RefreshReponse.self)
            .map { refreshResponse in
                guard refreshResponse.refresh else {
                    throw AuthenticationError.loginRequired
                }
            }
            .asObservable()
            .do(
                onNext: { [weak self] _ in self?.resetProgress() },
                onError: { [weak self] _ in self?.resetProgress() }
            )
        
        refreshInProgressObservable = refreshInProgress
        return refreshInProgress
    }
    
    func resetProgress() {
        queue.sync { [weak self] in
            self?.refreshInProgressObservable = nil
        }
    }
}
