//
//  Replication.swift
//  E2eSwiftSDKTests
//
//  Created by Grimberg, Jacob (GE Global Research) on 12/4/17.
//  Copyright © 2017 Jacob Grimberg. All rights reserved.
//

import XCTest
import PredixSDK


class Replication: XCTestCase {
    
    var replicationConfiguration: Database.ReplicationConfiguration!
    
    func setReplicationConfig(_ config: Database.ReplicationConfiguration){
        self.replicationConfiguration = config
    }
    
    func startDatabaseReplication(database: Database) {
        
        let statusDelegate = TestReplicationStatusDelegate(self)
        database.replicationStatusDelegate = statusDelegate
        
        statusDelegate.replicationIsReceiving = { db, details, received, totalToReceive in
            print("Receiving: \(received) of: \(totalToReceive)")
        }
        statusDelegate.expectations["replicationIsReceiving"]?.assertForOverFulfill = false
        
        statusDelegate.replicationDidComplete = { db, details in
            print("Replication complete")
        }
        
        database.startReplication(with: replicationConfiguration)

        self.waitForExpectations(timeout: 20, handler: nil)
        
        // Validate we have some documents
//        let documentCount = database.cbDatabase.documentCount
//        print("Replicated document count: \(documentCount)")
//        XCTAssertGreaterThan(documentCount, 0)
        
//        database.close()
    }

    
    internal class TestReplicationStatusDelegate: ReplicationStatusDelegate {
        
        private var testCase: XCTestCase
        internal var expectations: [String: XCTestExpectation] = [:]
        
        init(_ testCase: XCTestCase) {
            self.testCase = testCase
        }
        
        var replicationDidComplete: ((Database, ReplicationDetails) -> Void)? {
            didSet {
                let expectation = self.testCase.expectation(description: "replicationDidComplete")
                //expectation.assertForOverFulfill = false
                expectations["replicationDidComplete"] = expectation
            }
        }
        var replicationIsSending: ((Database, ReplicationDetails, Int, Int) -> Void)? {
            didSet {
                expectations["replicationIsSending"] = self.testCase.expectation(description: "replicationIsSending")
            }
        }
        var replicationIsReceiving: ((Database, ReplicationDetails, Int, Int) -> Void)? {
            didSet {
                expectations["replicationIsReceiving"] = self.testCase.expectation(description: "replicationIsReceiving")
            }
        }
        var replicationFailed: ((Database, ReplicationDetails, Error) -> Void)? {
            didSet {
                expectations["replicationFailed"] = self.testCase.expectation(description: "replicationFailed")
            }
        }
        
        func database(_ database: Database, replicationDidComplete details: ReplicationDetails) {
            if let closure = self.replicationDidComplete {
                defer {
                    expectations["replicationDidComplete"]?.fulfill()
                }
                closure(database, details)
            }
        }
        
        func database(_ database: Database, replicationIsSending details: ReplicationDetails, sent: Int, totalToSend: Int) {
            if let closure = self.replicationIsSending {
                defer {
                    expectations["replicationIsSending"]?.fulfill()
                }
                closure(database, details, sent, totalToSend)
            }
        }
        
        func database(_ database: Database, replicationIsReceiving details: ReplicationDetails, received: Int, totalToReceive: Int) {
            if let closure = self.replicationIsReceiving {
                defer {
                    expectations["replicationIsReceiving"]?.fulfill()
                }
                closure(database, details, received, totalToReceive)
            }
        }
        
        func database(_ database: Database, replicationFailed details: ReplicationDetails, error: Error) {
            if let closure = self.replicationFailed {
                defer {
                    expectations["replicationFailed"]?.fulfill()
                }
                closure(database, details, error)
            }
        }
    }

}
