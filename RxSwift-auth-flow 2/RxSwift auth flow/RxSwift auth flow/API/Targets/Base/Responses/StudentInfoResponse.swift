//
//  StudentInfoResponse.swift
//  RxSwift auth flow
//
//  Created by Anton Kovalenko on 21.01.2023.
//

import Foundation

struct StudentInfoResponse: Codable {
    let ID: Int
    let SYM_GROUP: String
    let NAME: String
    let SURNAME: String
}
