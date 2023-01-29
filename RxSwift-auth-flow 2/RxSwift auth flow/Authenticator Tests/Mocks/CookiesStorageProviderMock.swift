//
//  CookiesStorageProviderMock.swift
//  Authenticator Tests
//
//  Created by Anton Kovalenko on 12.01.2023.
//

import Foundation
@testable import RxSwift_auth_flow

final class CookiesStorageProviderMock: CookiesStorageProviderType {
    var isHaveValidAuthToken: Bool = true
    var isHaveValidRefreshToken: Bool = true
}
