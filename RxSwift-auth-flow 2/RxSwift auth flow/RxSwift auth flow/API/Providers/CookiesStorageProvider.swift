//
//  CookiesStorageProvider.swift
//  RxSwift auth flow
//
//  Created by Anton Kovalenko on 08.01.2023.
//

import Foundation

protocol CookiesStorageProviderType {
    var isHaveValidAuthToken: Bool { get }
    var isHaveValidRefreshToken: Bool { get }
}

final class CookiesStorageProvider: CookiesStorageProviderType {
    var isHaveValidAuthToken: Bool {
        HTTPCookieStorage.shared.cookies?.contains(where: { $0.name == "access_token_cookie" }) ?? false
    }

    var isHaveValidRefreshToken: Bool {
        HTTPCookieStorage.shared.cookies?.contains(where: { $0.name == "refresh_token_cookie" }) ?? false
    }
}
