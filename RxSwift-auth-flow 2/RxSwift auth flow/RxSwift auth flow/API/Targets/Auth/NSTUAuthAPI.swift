//
//  NSTUAuthAPI.swift
//  RxSwift auth flow
//
//  Created by Anton Kovalenko on 03.01.2023.
//

import Foundation
import Moya

enum NSTUAuthAPI: Hashable {
    case authenticate(credentials: AuthCredentials)
    case refreshToken
}

extension NSTUAuthAPI: TargetType {
    var baseURL: URL {
        return URL(string: "https://api.test_api.com/v1.1/token")!
    }
    
    var path: String {
        switch self {
            case .authenticate:
                return "auth"
            case .refreshToken:
                return "refresh"
        }
    }
    
    var method: Moya.Method {
        switch self {
            case .authenticate:
                return .post
            case .refreshToken:
                return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
            case .authenticate:
                return .requestPlain
            case .refreshToken:
                return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        switch self {
            case let .authenticate(credentials):
                return [
                    "X-OpenAM-Username": credentials.email,
                    "X-OpenAM-Password": credentials.password
                ]
            case .refreshToken:
                return nil
        }
    }
}
