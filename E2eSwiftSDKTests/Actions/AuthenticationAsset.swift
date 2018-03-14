//
//  AuthenticationAsset.swift
//  E2eSwiftSDKTests
//
//  Created by Grimberg, Jacob (GE Global Research) on 2/1/18.
//  Copyright © 2018 Jacob Grimberg. All rights reserved.
//

import XCTest
import PredixSDK


class AuthenticationAsset: XCTestCase, ServiceBasedAuthenticationHandlerDelegate {
    
    private let userName = Utilities.configValueForKey("user_name_asset", location: .infoplist) as? String
    private let userPwd = Utilities.configValueForKey("user_pwd_asset", location: .infoplist) as? String
    
    func authenticate(_ endpoint: String, clientId: String, clientSecret: String) {
        
        Utilities.predixSyncURL = URL(string: endpoint)
        
        var authConfig = AuthenticationManagerConfiguration()
        authConfig.clientId = clientId
        authConfig.clientSecret = clientSecret
        authConfig.baseURL = URL(string: Utilities.configValueForKey("uaa_url_asset") as! String)
        
        let manager = AuthenticationManager(configuration: authConfig)
        
        let serviceHandler = UAAServiceAuthenticationHandler()
        serviceHandler.authenticationServiceDelegate = self
        manager.onlineAuthenticationHandler = serviceHandler
        manager.authorizationHandler = UAAAuthorizationHandler()
        
        let authExpectation = self.expectation(description: "Service authentication")
        manager.authenticate { (status) in
            if case .success(_, let user) = status {
                XCTAssertEqual(user.userName(), "jacob.asset@ge.com", "username was not as expected")
                print("User authenticated: \(String(describing: user.userName()))")
            }
            authExpectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 50, handler: nil)
    }
    
    
    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, provideCredentialsWithCompletionHandler completionHandler: @escaping AuthenticationCredentialsProvider) {
        completionHandler(userName!,userPwd!)
    }
    
    func authenticationHandlerProvidedCredentialsWereInvalid(_ authenticationHandler: AuthenticationHandler) {
        XCTFail("Invalid credentials")
    }
    
    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, didFailWithError error: Error) {
        XCTFail("didFailWithError: \(error)")
    }
    
}
