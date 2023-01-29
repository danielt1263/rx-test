//
//  RxMoyaProviderMock.swift
//  Authenticator Tests
//
//  Created by Anton Kovalenko on 05.01.2023.
//

import XCTest
import RxSwift
import RxTest
import Moya
@testable import RxSwift_auth_flow

final class RxMoyaProviderMock<Target: TargetType>: RxMoyaProviderType where Target: Hashable {
    private(set) var recordedEvents: TestableObserver<Target>
    
    var responses: [Target: [TestableObservable<Response>]]
    
    init(scheduler: TestScheduler, responses: [Target: [TestableObservable<Response>]] = [:]) {
        recordedEvents = scheduler.createObserver(Target.self)
        self.responses = responses
    }
    
    func request(_ token: Target, callbackQueue: DispatchQueue?) -> Observable<Response> {
        recordedEvents.on(.next(token))
        guard var responsesArray = responses[token], !responsesArray.isEmpty else {
            XCTFail("There is no responses for token")
            return .never()
        }
        return responsesArray.removeFirst().asObservable()
    }
}
