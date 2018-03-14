//
//  DatabaseCRUDTests.swift
//  E2eSwiftSDK
//
//  Created by Grimberg, Jacob (GE Global Research) on 11/30/17.
//  Copyright © 2017 Jacob Grimberg. All rights reserved.
//

import UIKit
@testable import PredixSDK

class DatabaseCRUDTests {
    
//    var database: Database!
//
//    public init(id: String, location: URL){
//
//        let endpointString = "https://98h7v1.run.aws-usw02-pr.ice.predix.io"
//        let endpointURL = URL(string: endpointString)!
//        
//        self.authenticate(endpointString)
//        
//        let dbConfig = Database.OpenDatabaseConfiguration(name: "pm")
//        
//        do {
//            let db = try Database.open(with: dbConfig, create: false)
//            if let db = db {
//                database = db
//            } else {
//                print("Database open returned nil")
//            }
//        } catch let error {
//            print("Database open threw error: \(error)")
//        }
//
//        print("Connected")
//    
//    }
//    
//    private func authenticate(_ endpoint: String) {
//        PredixMobilityConfiguration.serverEndpoint = endpoint
//        guard let endpoint = PredixMobilityConfiguration.serverEndpoint else {
//            print("PredixMobililtyConfiguration serverEndpoint not set")
//            return
//        }
//        
//        var authConfig = AuthenticationManagerConfiguration()
//        authConfig.clientId = "jacob_mobile"
//        authConfig.clientSecret = "Test123"
//        authConfig.baseURL =  AuthenticationManagerConfiguration.fetchAuthenticationBaseURL(serverEndpoint: endpoint)
//        
//        let manager = AuthenticationManager(configuration: authConfig)
//        
//        let serviceDelegate = TestServiceHandlerDelegate()
//        
//        let serviceHandler = UAAServiceAuthenticationHandler()
//        serviceHandler.authenticationServiceDelegate = serviceDelegate
//        manager.onlineAuthenticationHandler = serviceHandler
//        manager.authorizationHandler = PredixMobileAuthorizationHandler()
//        
////        let authExpectation = self.expectation(description: "Service authentication")
//        manager.authenticate { (status) in
//            if case .success(_, let user) = status {
//                print("username correct")
//            }
////            authExpectation.fulfill()
//        }
////        self.waitForExpectations(timeout: defaultWait, handler: nil)
//    }
//
//
//
}

private class TestServiceHandlerDelegate: ServiceBasedAuthenticationHandlerDelegate {
    var stop = false
    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, provideCredentialsWithCompletionHandler completionHandler: @escaping AuthenticationCredentialsProvider) {
        if !stop {
            completionHandler("jacob@ge.com", "Test123")
        }
    }
    func authenticationHandlerProvidedCredentialsWereInvalid(_ authenticationHandler: AuthenticationHandler) {
        stop = true
        print("Invalid credentials")
    }
    
    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, didFailWithError error: Error) {
        stop = true
        print("didFailWithError: \(error)")
    }
}

