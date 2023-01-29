//
//  TokenRefreshExampleViewController.swift
//  RxSwift auth flow
//
//  Created by Anton Kovalenko on 03.01.2023.
//

import UIKit
import RxSwift
import RxCocoa
import Moya

final class TokenRefreshExampleViewController: UIViewController {
    @IBOutlet private var setWeeksRequest: UIButton!
    @IBOutlet private var setGroupsRequest: UIButton!
    @IBOutlet private var sendRequestButton: UIButton!
    @IBOutlet private var sendStudentInfoRequestButton: UIButton!
    
    
    private let disposeBag = DisposeBag()
    private let authenticator: AuthenticatorType = {
        let provider = RxMoyaProvider<NSTUAuthAPI>(provider: .init())
        let cookiesStorageProvider = CookiesStorageProvider()
        return Authenticator(provider: provider, cookiesStorageProvider: cookiesStorageProvider)
    }()
    
    lazy var appAPIProvider = {
        let provider = RxMoyaProvider<AppAPI>(provider: .init())
        let appAPIProvider = AuthorizedRxMoyaProvider<RxMoyaProvider<AppAPI>>(
            authenticator: authenticator,
            provider: provider
        )
        return AppAPIProvider(provider: appAPIProvider)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sendRequestButton.rx.tap.asSignal()
            .flatMapLatest { [weak self] _ in
                self?.authenticator.authenticate().asSignal(onErrorSignalWith: .never()) ?? .empty()
            }
            .emit()
            .disposed(by: disposeBag)
        
        setWeeksRequest.rx.tap.asSignal()
            .flatMapLatest { [weak self] _ in
                self?.appAPIProvider.getWeeks().asSignal(onErrorSignalWith: .never()) ?? .empty()
            }
            .emit()
            .disposed(by: disposeBag)
                
        setGroupsRequest.rx.tap.asSignal()
            .flatMapLatest { [weak self] _ in
                self?.appAPIProvider.getGroups().asSignal(onErrorSignalWith: .never()) ?? .empty()
            }
            .emit()
            .disposed(by: disposeBag)
        
        sendStudentInfoRequestButton.rx.tap.asSignal()
            .flatMapLatest { [weak self] _ in
                self?.appAPIProvider.getStudentInfo().asSignal(onErrorSignalWith: .never()) ?? .empty()
            }
            .emit()
            .disposed(by: disposeBag)
    }
    
    
    @IBAction func deleteAuthTokenTapped(_ sender: Any) {
        guard let authCookie = HTTPCookieStorage.shared.cookies?.first(where: { $0.name == "access_token_cookie" }) else {
            return
        }
        HTTPCookieStorage.shared.deleteCookie(authCookie)
    }
    
    
    @IBAction func deleteAllTokensTapped(_ sender: Any) {
        (HTTPCookieStorage.shared.cookies ?? []).forEach({ cookie in
            HTTPCookieStorage.shared.deleteCookie(cookie)
        })
    }
}
