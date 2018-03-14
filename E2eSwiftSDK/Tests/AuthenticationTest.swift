//
//  AuthenticationTest.swift
//  E2eSwiftSDK
//
//  Created by Grimberg, Jacob (GE Global Research) on 11/29/17.
//  Copyright © 2017 Jacob Grimberg. All rights reserved.
//

import UIKit
import PredixSDK

class AuthenticationTest: ServiceBasedAuthenticationHandlerDelegate {
    
    private var credentialProvider: AuthenticationCredentialsProvider?
    private var authenticationManager: AuthenticationManager?

    public func authenticate(){
        
        var configuration = AuthenticationManagerConfiguration()
        
        var url_uaa : String!
        if let url = Bundle.main.object(forInfoDictionaryKey: "uaa_url") as? String {
            url_uaa = url
        }
        
        configuration.baseURL = URL(string: url_uaa)
        
        //Create an online handler so that we can tell the authentication manager we want to authenticate online
        let onlineHandler = UAAServiceAuthenticationHandler()
        onlineHandler.authenticationServiceDelegate = self

        authenticationManager = AuthenticationManager(configuration: configuration)
        authenticationManager?.authorizationHandler = UAAAuthorizationHandler()
        authenticationManager?.onlineAuthenticationHandler = onlineHandler
        
        //Tell authentication manager we are ready to authenticate, once we call authenticate it will call our delegate with the credential provider
        authenticationManager?.authenticate { status in
            
            if case AuthenticationManager.AuthenticationCompletionStatus.success(let type, let user) = status {
                print("type: \(type), user: \(user)")
                print("Jacob Authentication status -> status: \(status)")
                
            }
        }

    }
    
    
    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, provideCredentialsWithCompletionHandler completionHandler: @escaping AuthenticationCredentialsProvider) {
        
        credentialProvider = completionHandler
    }
    
    public func authenticationHandler(_ authenticationHandler: PredixSDK.AuthenticationHandler, didFailWithError error: Error) {
        
        print("Authentication status failed -> status: \(error)")

    }
    
    public func authenticationHandlerProvidedCredentialsWereInvalid(_ authenticationHandler: AuthenticationHandler) {

        print("Authentication status failed -> invalid credentials: \(authenticationHandler)")

    }

}
