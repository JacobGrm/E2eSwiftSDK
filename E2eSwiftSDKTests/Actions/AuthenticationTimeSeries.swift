//
//  AuthenticationTimeSeries.swift
//  E2eSwiftSDKTests
//
//  Created by Grimberg, Jacob (GE Global Research) on 2/23/18.
//  Copyright © 2018 Jacob Grimberg. All rights reserved.
//

import XCTest
import PredixSDK

class AuthenticationTimeSeries: XCTestCase, ServiceBasedAuthenticationHandlerDelegate {
    
    var credentialProvider: AuthenticationCredentialsProvider?
    var authenticationManager: AuthenticationManager?
    
    func authenticate(_ endpoint: String, clientId: String, clientSecret: String) {
        
        var configuration = AuthenticationManagerConfiguration()
        configuration.clientId = clientId
        configuration.clientSecret = clientSecret
        configuration.baseURL = URL(string: endpoint)

        let onlineHandler = UAAServiceAuthenticationHandler()
        onlineHandler.authenticationServiceDelegate = self

        authenticationManager = AuthenticationManager(configuration: configuration)
        authenticationManager?.authorizationHandler = UAAAuthorizationHandler()
        authenticationManager?.onlineAuthenticationHandler = onlineHandler
        
        let authExpectation = self.expectation(description: "Service authentication")

        authenticationManager?.authenticate { status in
            print("Authentication Time Series status: \(status)")
            switch status {
            case .success(_, _):
                print("Authentication Time Series success: \(status)")
                break
            default: break
            }
            
            authExpectation.fulfill()
        }

        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, provideCredentialsWithCompletionHandler completionHandler: @escaping AuthenticationCredentialsProvider) {
        print("authenticationHandler called")
        completionHandler("jacob.ts","Test123")
        credentialProvider = completionHandler
    }
    
    func authenticationHandlerProvidedCredentialsWereInvalid(_ authenticationHandler: AuthenticationHandler) {
        XCTFail("Invalid credentials")
    }
    
    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, didFailWithError error: Error) {
        XCTFail("didFailWithError: \(error)")
    }

    
}
