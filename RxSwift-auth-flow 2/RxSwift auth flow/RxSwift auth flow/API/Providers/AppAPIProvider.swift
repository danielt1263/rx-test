//
//  AppAPIProvider.swift
//  RxSwift auth flow
//
//  Created by Anton Kovalenko on 05.01.2023.
//

import Moya
import RxSwift

protocol AppAPIProviderType {
    func getWeeks() -> Observable<Int?>
    func getGroups() -> Observable<[GroupInfoResponse]>
    func getStudentInfo() -> Observable<StudentInfoResponse?>
}

final class AppAPIProvider<Provider: RxMoyaProviderType> where Provider.Target == AppAPI {
    private let provider: AuthorizedRxMoyaProvider<Provider>
    
    init(provider: AuthorizedRxMoyaProvider<Provider>) {
        self.provider = provider
    }
}

extension AppAPIProvider: AppAPIProviderType {
    func getWeeks() -> Observable<Int?> {
        provider.request(.weekNumber)
            .map([WeekNumberResponse].self)
            .map { $0.first?.WEEK }
    }
    
    func getGroups() -> Observable<[GroupInfoResponse]> {
        provider.request(.studyGroups)
            .map([GroupInfoResponse].self)
    }
    
    func getStudentInfo() -> Observable<StudentInfoResponse?> {
        provider.request(.studentInfo)
            .map([StudentInfoResponse].self)
            .map { $0.first }
    }
}
