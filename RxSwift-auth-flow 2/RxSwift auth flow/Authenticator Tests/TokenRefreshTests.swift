//
//  TokenRefreshTests.swift
//  Authenticator Tests
//
//  Created by Anton Kovalenko on 04.01.2023.
//

import XCTest
import Moya
import RxBlocking
import RxTest
import RxSwift
@testable import RxSwift_auth_flow

final class TokenRefreshTests: XCTestCase {
    private var cookiesStorageProviderMock: CookiesStorageProviderMock!
    
    private var appAPIProviderMock: RxMoyaProviderMock<NSTUAppAPI>!
    private var authAPIProviderMock: RxMoyaProviderMock<NSTUAuthAPI>!
    
    private var authenticator: Authenticator<RxMoyaProviderMock<NSTUAuthAPI>>!
    private var nstuAppAPIProvder: NSTUAppAPIProvider<RxMoyaProviderMock<NSTUAppAPI>>!
    
    private var scheduler: TestScheduler!
    private var disposeBag: DisposeBag!
    
    private let jsonEncoder = JSONEncoder()
    
    override func setUpWithError() throws {
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
        
        cookiesStorageProviderMock = CookiesStorageProviderMock()

        appAPIProviderMock = RxMoyaProviderMock<NSTUAppAPI>(scheduler: scheduler)
        authAPIProviderMock = RxMoyaProviderMock<NSTUAuthAPI>(scheduler: scheduler)
        
        authenticator = Authenticator(
            provider: authAPIProviderMock,
            cookiesStorageProvider: cookiesStorageProviderMock
        )
        
        let autorizedRxMoyaProvider = AuthorizedRxMoyaProvider<RxMoyaProviderMock<NSTUAppAPI>>(
            authenticator: authenticator,
            provider: appAPIProviderMock
        )
        nstuAppAPIProvder = NSTUAppAPIProvider<RxMoyaProviderMock<NSTUAppAPI>>(
            provider: autorizedRxMoyaProvider
        )
    }
    
    func testAuthorizedRequest_WhenUserHaveValidAuthToken_ShouldJustReturnResponse() throws {
        let weekNumberResponse = [WeekNumberResponse(WEEK: 19)]
        let weekNumberResponseData = try jsonEncoder.encode(weekNumberResponse)
        
        appAPIProviderMock.responses = [
            .weekNumber: [
                scheduler.createColdObservable([
                    .next(10, .init(statusCode: 200, data: weekNumberResponseData))
                ])
            ]
        ]

        let weekResponseObserver = scheduler.createObserver(Int?.self)

        nstuAppAPIProvder.getWeeks()
            .subscribe(weekResponseObserver)
            .disposed(by: disposeBag)
        
        
        scheduler.start()
        
        XCTAssertEqual(authAPIProviderMock.recordedEvents.events, [])
        XCTAssertEqual(appAPIProviderMock.recordedEvents.events, [
            .next(0, .weekNumber)
        ])
        XCTAssertEqual(weekResponseObserver.events, [
            .next(10, 19)
        ])
    }

    func testAuthorizedRequest_WhenUserNotHaveValidAuthTokenAndRefreshSuccesss_ShouldReturnResponse() throws {
        cookiesStorageProviderMock.isHaveValidAuthToken = false
        
        let refreshReponse = RefreshReponse(refresh: true)
        let refreshResponseData = try jsonEncoder.encode(refreshReponse)
        
        authAPIProviderMock.responses = [
            .refreshToken: [
                scheduler.createColdObservable([
                    .next(10, .init(statusCode: 200, data: refreshResponseData))
                ])
            ]
        ]
        
        let weekNumberResponse = [WeekNumberResponse(WEEK: 19)]
        let weekNumberResponseData = try jsonEncoder.encode(weekNumberResponse)
        
        appAPIProviderMock.responses = [
            .weekNumber: [
                scheduler.createColdObservable([
                    .next(10, .init(statusCode: 200, data: weekNumberResponseData))
                ])
            ]
        ]

        let weekResponseObserver = scheduler.createObserver(Int?.self)

        nstuAppAPIProvder.getWeeks()
            .subscribe(weekResponseObserver)
            .disposed(by: disposeBag)
        
        
        scheduler.start()
        
        XCTAssertEqual(authAPIProviderMock.recordedEvents.events, [
            .next(0, .refreshToken)
        ])
        XCTAssertEqual(appAPIProviderMock.recordedEvents.events, [
            .next(10, .weekNumber)
        ])
        XCTAssertEqual(weekResponseObserver.events, [
            .next(20, 19)
        ])
    }
    
    func testAuthorizedRequest_WhenUserNotHaveValidAuthTokenAndRefreshFailed_ShouldCallRefreshTokenTwiceAndFail() throws {
        cookiesStorageProviderMock.isHaveValidAuthToken = false
        
        let refreshReponse = RefreshReponse(refresh: true)
        let refreshResponseData = try jsonEncoder.encode(refreshReponse)
        
        authAPIProviderMock.responses = [
            .refreshToken: [
                scheduler.createColdObservable([
                    .error(10, AuthenticationError.loginRequired)
                ])
            ]
        ]

        let weekNumberResponse = [WeekNumberResponse(WEEK: 19)]
        let weekNumberResponseData = try jsonEncoder.encode(weekNumberResponse)
        
        appAPIProviderMock.responses = [
            .weekNumber: [
                scheduler.createColdObservable([
                    .next(10, .init(statusCode: 200, data: weekNumberResponseData))
                ])
            ]
        ]
        
        let groupInfoResponse = [GroupInfoResponse]()
        let groupInfoResponseData = try jsonEncoder.encode(groupInfoResponse)
        
        appAPIProviderMock.responses = [
            .studyGroups: [
                scheduler.createColdObservable([
                    .next(10, .init(statusCode: 200, data: groupInfoResponseData))
                ])
            ]
        ]

        let weekResponseObserver = scheduler.createObserver(Int?.self)
        let groupsResponseObserver = scheduler.createObserver([GroupInfoResponse].self)
        
        let getWeeksTrigerredObservable = scheduler.createColdObservable([.next(0, ())])
        let getGroupsTrigerredObservable = scheduler.createColdObservable([.next(5, ())])

        getWeeksTrigerredObservable.asObservable()
            .flatMapLatest { [weak self] in
                self?.nstuAppAPIProvder.getWeeks() ?? .never()
            }
            .subscribe(weekResponseObserver)
            .disposed(by: disposeBag)


        getGroupsTrigerredObservable.asObservable()
            .flatMapLatest { [weak self] in
                self?.nstuAppAPIProvder.getGroups() ?? .never()
            }
            .subscribe(groupsResponseObserver)
            .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(weekResponseObserver.events, [
            .error(20, AuthenticationError.loginRequired)
        ])
        
        // Вот тут ошибка, запрос на обновление токена посылается дважды,
        // если первый раз запрос на обновление токена зафейлился
        XCTAssertEqual(authAPIProviderMock.recordedEvents.events, [
            .next(0, .refreshToken),
            .next(10, .refreshToken)
        ])
        
        XCTAssertEqual(groupsResponseObserver.events, [
            .error(20, AuthenticationError.loginRequired)
        ])
    }
}
