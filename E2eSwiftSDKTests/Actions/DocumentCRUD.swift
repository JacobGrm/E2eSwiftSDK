//
//  DocumentCRUD.swift
//  E2eSwiftSDKTests
//
//  Created by Grimberg, Jacob (GE Global Research) on 12/6/17.
//  Copyright © 2017 Jacob Grimberg. All rights reserved.
//

import XCTest
//@testable import PredixSDK
import PredixSDK


class DocumentCRUD: XCTestCase {
    
    var database: Database!
    
    var fetchedDoc: Document! = nil
    var error: Error?
    
    var fetchedDocs = [Document]()
    
    enum SomethingWrong: Error {
        
        case errorFetchingDocument
    }

    func setDatabase(_ database: Database){
        self.database = database
    }
    
    func createTestDocument (docId: String, properties: Document.DictionaryType = ["foo": "bar", Document.MetadataKeys.type: "testDoc", Document.MetadataKeys.channels: ["test"]]) -> Document {
        
        let dic: Document.DictionaryType = ["_id": docId] + properties
        return Document(dic)
    }
    
    func addDocumentToDatabase(_ document: Document) {
        
        let expectation = self.expectation(description: #function)
        
        self.database.add(document) { (result) in
            switch result {
            case .success(let savedDocument):
                print("Success creating document: \(savedDocument)")
                self.fetchedDoc = savedDocument
                self.error = nil
            case .failed(let error):
                self.error = error
                self.fetchedDoc = nil
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 10)
    }

    func updateDocumentToDatabase(_ document: Document) {
        
        let expectation = self.expectation(description: #function)
        
        self.database.update(document, completionHandler: { (result) in
            switch result {
            case .success(let updatedDocument):
                self.fetchedDoc = updatedDocument
                self.error = nil
            case .failed(let error):
                self.error = error
                self.fetchedDoc = nil
            }
            expectation.fulfill()
        })

        self.waitForExpectations(timeout: 5)
    }
    
    func getDocument(_ document: Document) {
        
        let expectation = self.expectation(description: #function)
        
        let docId = document.id
        self.database.fetchDocument(docId) { (fetchedDoc) in
            
                self.fetchedDoc = fetchedDoc
                self.error = nil
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 100)
    }

    
    func getDocuments(_ documents: [Document]) {
        
        let expectation = self.expectation(description: #function)
        
        var ids = [String]()
        
        for doc in documents {
            ids.append(doc.id)
        }
        
        self.database.fetchDocuments(ids) { (results) in
            for id in ids {
                if let doc = results[id] {
                    self.fetchedDocs.append(doc)
                } else {
                    self.error = SomethingWrong.errorFetchingDocument
                }
            }
            
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 100)
    }

    
    func deleteDocument(_ document: Document) {
        
        let expectation = self.expectation(description: #function)
        let docId = document.id
        
        self.database.delete(documentWithId: docId) { (result) in
            switch result {
            case .success(_):
                self.database.fetchDocument(docId, completionHandler: { (deletedDoc) in
                    self.fetchedDoc = deletedDoc
                    self.error = nil
                })
            case .failed(let error):
                self.error = error
                self.fetchedDoc = nil
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5)
    }

}
