//
//  AuthCredentials.swift
//  RxSwift auth flow
//
//  Created by Anton Kovalenko on 07.01.2023.
//

import Foundation

struct AuthCredentials: Hashable {
    let email: String
    let password: String
}

extension AuthCredentials {
    static var `defaultDebugAccount` = AuthCredentials(
        email: "test_account",
        password: "854324532"
    )
}
