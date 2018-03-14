//
//  OpenDatabase.swift
//  E2eSwiftSDKTests
//
//  Created by Grimberg, Jacob (GE Global Research) on 12/4/17.
//  Copyright © 2017 Jacob Grimberg. All rights reserved.
//

import XCTest
import PredixSDK

class OpenDatabase: XCTestCase {
    
    func openDatabase(endpoint: String, name: String) -> Database {
        
        var database: Database?
        
        let dbConfig = Database.OpenDatabaseConfiguration(name: name)
        
        do {
            let db = try Database.open(with: dbConfig, create: true)
            if let db = db {
                database = db
            } else {
                XCTFail("Database open returned nil")
                database = nil
            }
        } catch let error {
            XCTFail("Database open threw error: \(error)")
        }
        
        return database!
    }

}
