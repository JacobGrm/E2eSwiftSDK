//
//  Authentication.swift
//  E2eSwiftSDKTests
//
//  Created by Grimberg, Jacob (GE Global Research) on 12/1/17.
//  Copyright © 2017 Jacob Grimberg. All rights reserved.
//

import XCTest
import PredixSDK


class Authentication: XCTestCase, ServiceBasedAuthenticationHandlerDelegate {
    
    func authenticate(_ endpoint: String, clientId: String, clientSecret: String) {
        
        Utilities.predixSyncURL = URL(string: endpoint)
        
        var authConfig = AuthenticationManagerConfiguration()
        authConfig.clientId = clientId
        authConfig.clientSecret = clientSecret
        authConfig.baseURL =  AuthenticationManagerConfiguration.fetchAuthenticationBaseURL(serverEndpoint: endpoint)
        
        let manager = AuthenticationManager(configuration: authConfig)
        
        let serviceHandler = UAAServiceAuthenticationHandler()
        serviceHandler.authenticationServiceDelegate = self
        manager.onlineAuthenticationHandler = serviceHandler
        manager.authorizationHandler = PredixSyncAuthorizationHandler()

// Andy
//        let authorizationHandler = PredixSyncAuthorizationHandler(predixSyncURL: URL(string: endpoint))
//        manager.authorizationHandler = authorizationHandler
//        authorizationHandler.authorizationURLPath =
//                manager.authorizationHandler.

        let authExpectation = self.expectation(description: "Service authentication")
        manager.authenticate { (status) in
            if case .success(_, let user) = status {
                XCTAssertEqual(user.userName(), "jacob_ge_com", "username was not as expected")
                print("user authenticated")
            }
            authExpectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 50, handler: nil)
    }


    
    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, provideCredentialsWithCompletionHandler completionHandler: @escaping AuthenticationCredentialsProvider) {
        completionHandler("jacob@ge.com","Test123")
    }
    
    func authenticationHandlerProvidedCredentialsWereInvalid(_ authenticationHandler: AuthenticationHandler) {
        XCTFail("Invalid credentials")
    }
    
    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, didFailWithError error: Error) {
        XCTFail("didFailWithError: \(error)")
    }

}
