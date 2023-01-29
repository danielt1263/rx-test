//
//  AuthorizedRxMoyaProvider.swift
//  RxSwift auth flow
//
//  Created by Anton Kovalenko on 08.01.2023.
//

import Moya
import RxSwift

final class AuthorizedRxMoyaProvider<Provider: RxMoyaProviderType> {
    typealias Target = Provider.Target
    
    private let authenticator: AuthenticatorType
    private let provider: Provider
    
    init(
        authenticator: AuthenticatorType,
        provider: Provider
    ) {
        self.authenticator = authenticator
        self.provider = provider
    }
}

extension AuthorizedRxMoyaProvider: RxMoyaProviderType {
    func request(_ token: Target, callbackQueue: DispatchQueue?) -> Observable<Response> {
        authenticator.checkForValidAuthTokenOrRefresh()
            .flatMapLatest { [weak self] res -> Observable<Response> in
                self?.provider.request(token).asObservable() ?? .empty()
            }
            .map { response in
                guard response.statusCode != 401 else {
                    throw AuthenticationError.loginRequired
                }
                return response
            }
            .retry { [weak self] error in
                error.flatMap { error -> Observable<Void> in
                    guard let authError = error as? AuthenticationError, authError == .loginRequired else {
                        return .error(error)
                    }
                    
                    return self?.authenticator.checkForValidAuthTokenOrRefresh(forceRefresh: true) ?? .never()
                }
            }
    }
}
