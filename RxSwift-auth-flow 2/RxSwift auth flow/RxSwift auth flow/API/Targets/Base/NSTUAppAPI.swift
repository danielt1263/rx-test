//
//  NSTUAppAPI.swift
//  RxSwift auth flow
//
//  Created by Anton Kovalenko on 04.01.2023.
//

import Foundation
import Moya

enum AppAPI: Hashable {
    case weekNumber
    case studyGroups
    case studentInfo
}

extension AppAPI: TargetType {
    var baseURL: URL {
        return URL(string: "https://api.test_api.com/v1.1/student/get_data/app")!
    }
    
    var path: String {
        switch self {
            case .studyGroups:
                return "get_study_group"
            case .weekNumber:
                return "get_week_number"
            case .studentInfo:
                return "get_student_info"
        }
    }
    
    var method: Moya.Method {
        switch self {
            case .weekNumber:
                return .get
            case .studyGroups:
                return .get
            case .studentInfo:
                return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
            case .weekNumber:
                return .requestPlain
            case .studyGroups:
                return .requestPlain
            case .studentInfo:
                return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
}
