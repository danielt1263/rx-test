//
//  RxMoyaProvider.swift
//  RxSwift auth flow
//
//  Created by Anton Kovalenko on 08.01.2023.
//

import Moya
import RxSwift

protocol RxMoyaProviderType {
    associatedtype Target: TargetType
    
    func request(_ token: Target, callbackQueue: DispatchQueue?) -> Observable<Response>
}

extension RxMoyaProviderType {
    func request(_ token: Target, callbackQueue: DispatchQueue? = nil) -> Observable<Response> {
        request(token, callbackQueue: callbackQueue)
    }
}

final class RxMoyaProvider<Target: TargetType>: RxMoyaProviderType {
    private let provider: MoyaProvider<Target>
    
    init(provider: MoyaProvider<Target>) {
        self.provider = provider
    }
    
    func request(_ token: Target, callbackQueue: DispatchQueue?) -> Observable<Response> {
        provider.rx.request(token).asObservable()
    }
}
