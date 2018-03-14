//
//  E2eSwiftSDKTests.swift
//  E2eSwiftSDKTests
//
//  Created by Jacob Grimberg on 11/6/17.
//  Copyright © 2017 General Electric. All rights reserved.
//

import XCTest
import PredixSDK

class E2eSwiftSDKTests: XCTestCase {
    
    var database: Database!
    
    var urlDatabase: String!
    var dbName: String!
    var clientId: String!
    var clientSecret: String!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Utilities.predixSyncURL = Utilities.retreivePredixSyncURLFromConfig(location: .infoplist)
        urlDatabase = Utilities.predixSyncURL!.absoluteString
        
        clientId = Utilities.configValueForKey("client_id") as! String
        clientSecret = Utilities.configValueForKey("client_secret") as! String
        
        dbName = "pm"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        if let db = self.database {
            db.close()
        }
        super.tearDown()
    }
    
    func startReplication(replicationConfiguration: Database.ReplicationConfiguration) {
        
        let replication = Replication()
        let authenticator = Authentication()
        let dbOpen = OpenDatabase()
        
        authenticator.authenticate(urlDatabase, clientId: clientId, clientSecret: clientSecret)
        
        self.database = dbOpen.openDatabase(endpoint: urlDatabase, name: dbName)
        
        replication.setReplicationConfig(replicationConfiguration)
        replication.startDatabaseReplication(database: self.database)

    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    // Description:
    // Command should be synced back to the client
    // after processed by command processor with replication set
    // to repeatingBidirectionalReplication
    func testCommandProcessorRepeatingBidirecReplication() {

        let commandId: String! = "CMD_TEST_"+Document.idFactory()
        let commandProcessorRoute: String! = "/CMDP_CONFLICTS/process"

        self.startReplication(replicationConfiguration: Database.ReplicationConfiguration.repeatingBidirectionalReplication(with: URL(string: urlDatabase)!))

        // Add document
        let docHandler = DocumentCRUD()
        docHandler.setDatabase(database)

        let changeDic: [Document.Key: Document.Value] = ["somechange": 12345]
        let requestBody: [Document.Key: Document.Value] = ["docID": "someDocumentId", "change": changeDic]

        let innerDictionary: [Document.Key: Document.Value] = ["uri": commandProcessorRoute, "method": "PUT", "headers": [:], "body": requestBody]

        let dictionary: Document.DictionaryType = ["type": "command",
                                                   "~userid": "jacob_ge_com",
                                                   "channels": ["entity_jacob_ge_com","role-user"],
                                                   "~status": "pending", "request": innerDictionary]

        print("Command dictionary: \(dictionary)")

        let document: Document = docHandler.createTestDocument(docId: commandId, properties: dictionary)

        docHandler.addDocumentToDatabase(document)
        XCTAssertEqual(document.id, docHandler.fetchedDoc.id, "Saved document id did not match")

        sleep(10)

        //Verify command was processed by command processor
        docHandler.getDocument(document)
        XCTAssertEqual(docHandler.fetchedDoc?.id, document.id)
        XCTAssertEqual(docHandler.fetchedDoc?.properties["~status"] as! String, "success")
        // Verify command revision was bumped from 1 to 2
        XCTAssertEqual(docHandler.fetchedDoc?.metaData.revision.first, "2")

    }

    // Description:
    // Command should NOT be synced back to the client
    // after processed by command processor with replication set
    // to oneTimeServerToClientReplication
    func testCommandProcessorOneTimeServerToClientReplication() {

        let commandId: String! = "CMD_TEST_"+Document.idFactory()
        let commandProcessorRoute: String! = "/CMDP_CONFLICTS/process"

        self.startReplication(replicationConfiguration: Database.ReplicationConfiguration.oneTimeServerToClientReplication(with: URL(string: urlDatabase)!))

        // Add document
        let docHandler = DocumentCRUD()
        docHandler.setDatabase(database)

        let changeDic: [Document.Key: Document.Value] = ["somechange": 12345]
        let requestBody: [Document.Key: Document.Value] = ["docID": "someDocumentId", "change": changeDic]

        let innerDictionary: [Document.Key: Document.Value] = ["uri": commandProcessorRoute, "method": "PUT", "headers": [:], "body": requestBody]

        let dictionary: Document.DictionaryType = ["type": "command",
                                                   "~userid": "jacob_ge_com",
                                                   "channels": ["entity_jacob_ge_com","role-user"],
                                                   "~status": "pending", "request": innerDictionary]

        print("Command dictionary: \(dictionary)")

        let document: Document = docHandler.createTestDocument(docId: commandId, properties: dictionary)

        docHandler.addDocumentToDatabase(document)
        XCTAssertEqual(document.id, docHandler.fetchedDoc.id, "Saved document id did not match")

        sleep(5)

        //Verify command was replicated back to the client
        docHandler.getDocument(document)
        XCTAssertEqual(docHandler.fetchedDoc?.properties["~status"] as! String, "pending")
        XCTAssertEqual(docHandler.fetchedDoc?.metaData.revision.first, "1")
    }
    

    // Description:
    // Attempt to add attachment to deleted doc
    // Expected: should result in error
    func testAttachmentToDeletedDocument() {
        
        // open database
        self.startReplication(replicationConfiguration: Database.ReplicationConfiguration.repeatingBidirectionalReplication(with: URL(string: urlDatabase)!))
        
        // create document
        let docId: String! = "DOC_TEST_"+Document.idFactory()
        print("testAttachmentToDeletedDocument docId: \(docId)")
        
        // Add document
        let docHandler = DocumentCRUD()
        docHandler.setDatabase(database)
        
        let document: Document = docHandler.createTestDocument(docId: docId)
        
        docHandler.addDocumentToDatabase(document)
        XCTAssertEqual(document.id, docHandler.fetchedDoc.id, "Saved document id did not match")
        
        // delete document
        docHandler.deleteDocument(document)
        XCTAssertNil(docHandler.error, "Error attempting to access doc")
        XCTAssertNil(docHandler.fetchedDoc, "Deleted doc should return nil")
        
        // Get attachment
        let attachmentUrl: URL = Bundle.main.url(forResource: "predix-cli-0.6.16", withExtension: "zip")!
        let data = try? Data(contentsOf: attachmentUrl)
        let attachment = DocumentAttachment(name: attachmentUrl.absoluteString, contentType: "application/octet-stream", data: data!)
        
        // Attempt to add attachment to deleted document
        document.attachments.append(attachment)
        docHandler.updateDocumentToDatabase(document)
        
        XCTAssertNotNil(docHandler.error, "Error updating document should occur when doc attachment is not valid")

    }
 
    // Description:
    // Remove document attachment
    //    create doc with attachment,
    //    remove attachment
    // Number of revisions should be 2:
    func testRemoveDocumentAttachment() {
        
        // Create text file to be attached to document
        let str = "Super long string here"
        let attachmentName = "output.txt"
        
        let filename = getDocumentsDirectory().appendingPathComponent(attachmentName)
        
        do {
            try str.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            print("failed to write file")
        }
        
        // Attach this file to document
        let data = str.data(using: .utf8)!
        
        let attachment = DocumentAttachment(name: filename.absoluteString, contentType: "text/plain", data: data)
        
        // open database
        self.startReplication(replicationConfiguration: Database.ReplicationConfiguration.repeatingBidirectionalReplication(with: URL(string: urlDatabase)!))
        
        // create document
        let docId: String! = "DOC_TEST_"+Document.idFactory()
        print("testDocumentAtatchmentTextFile docId: \(docId)")
        
        // Add document
        let docHandler = DocumentCRUD()
        docHandler.setDatabase(database)
        
        let document: Document = docHandler.createTestDocument(docId: docId)
        document.attachments.append(attachment)
        
        docHandler.addDocumentToDatabase(document)
        
        // Verify document attachment
        XCTAssertEqual(document.id, docHandler.fetchedDoc.id, "Document id did not match")
        XCTAssertEqual(1, docHandler.fetchedDoc.attachments.count, "Document did not contain expected number of attachments")

        // Remove document attachments
        document.attachments.removeAll()
        docHandler.updateDocumentToDatabase(document)

        docHandler.getDocument(document)
        XCTAssertEqual(0, docHandler.fetchedDoc.attachments.count, "Updated document did not contain expected number of attachments")
        XCTAssertEqual("2", docHandler.fetchedDoc.metaData.revision.first, "Document revision was not updated")

    }
 
    // Description:
    // Add zip attachment to document
    // zip was added to application bundle
    func testAddDocumentZipAttachment() {
        
        let attachmentUrl: URL = Bundle.main.url(forResource: "predix-cli-0.6.16", withExtension: "zip")!
        
        let data = try? Data(contentsOf: attachmentUrl)
        
        let attachment = DocumentAttachment(name: attachmentUrl.absoluteString, contentType: "application/octet-stream", data: data!)
        
        // open database
        self.startReplication(replicationConfiguration: Database.ReplicationConfiguration.repeatingBidirectionalReplication(with: URL(string: urlDatabase)!))
        
        // create document
        let docId: String! = "DOC_TEST_"+Document.idFactory()
        print("testAddDocumentZipAttachment docId: \(docId)")
        
        // Add document
        let docHandler = DocumentCRUD()
        docHandler.setDatabase(database)
        
        let document: Document = docHandler.createTestDocument(docId: docId)
        document.attachments.append(attachment)
        
        docHandler.addDocumentToDatabase(document)
        
        // Verify document attachment
        XCTAssertEqual(document.id, docHandler.fetchedDoc.id, "Updated document id did not match")
        
        docHandler.getDocument(document)
        XCTAssertEqual(1, docHandler.fetchedDoc.attachments.count, "Updated document did not contain expected number of attachments")
        XCTAssertEqual(data?.count, docHandler.fetchedDoc.attachments[0].data.count, "Attachment size does not match")
        XCTAssertTrue(docHandler.fetchedDoc.attachments[0].name.contains("predix-cli-0.6.16.zip"), "Attachment name is wrong")

    }
    
    
    // Description:
    // Delete document
    func testDeleteDocument() {
        
        // open database
        self.startReplication(replicationConfiguration: Database.ReplicationConfiguration.repeatingBidirectionalReplication(with: URL(string: urlDatabase)!))
        
        // create document
        let docId: String! = "DOC_TEST_"+Document.idFactory()
        print("testDeleteDocument docId: \(docId)")
        
        // Add document
        let docHandler = DocumentCRUD()
        docHandler.setDatabase(database)
        
        let document: Document = docHandler.createTestDocument(docId: docId)

        docHandler.addDocumentToDatabase(document)
        XCTAssertEqual(document.id, docHandler.fetchedDoc.id, "Saved document id did not match")
        
        // delete document
        docHandler.deleteDocument(document)
        XCTAssertNil(docHandler.error, "Error attempting to doc")
        XCTAssertNil(docHandler.fetchedDoc, "Deleted doc should not be fetched")
        
        docHandler.getDocument(document)
        XCTAssertEqual(docHandler.fetchedDoc, nil)
    }

    // Description:
    // Delete non existing document
    // If a document doesn’t exist, the “delete” is considered successful
    func testDeleteNonExistingDocument() {
        
        // open database
        self.startReplication(replicationConfiguration: Database.ReplicationConfiguration.repeatingBidirectionalReplication(with: URL(string: urlDatabase)!))
        
        // create document object
        let docId: String! = "DOC_TEST_"+Document.idFactory()
        print("testDeleteNonExistingDocument docId: \(docId)")

        let docHandler = DocumentCRUD()
        docHandler.setDatabase(database)

        let document: Document = docHandler.createTestDocument(docId: docId)

        // delete document
        docHandler.deleteDocument(document)
        XCTAssertNil(docHandler.error, "Error attempting to doc")
        XCTAssertNil(docHandler.fetchedDoc, "Deleted doc should not be fetched")
        
        docHandler.getDocument(document)
        XCTAssertEqual(docHandler.fetchedDoc, nil)
    }
    
    func testUpdateNonExistingDocument() {
        
        // open database
        self.startReplication(replicationConfiguration: Database.ReplicationConfiguration.repeatingBidirectionalReplication(with: URL(string: urlDatabase)!))
        
        // create document object w/o adding it to database
        let docId: String! = "DOC_TEST_"+Document.idFactory()
        print("testRemoveDocumentAttachment docId: \(docId)")
        
        // Add document
        let docHandler = DocumentCRUD()
        docHandler.setDatabase(database)
        
        let document: Document = docHandler.createTestDocument(docId: docId)
        
        docHandler.updateDocumentToDatabase(document)
        XCTAssertNotNil(docHandler.error, "Error was not generated on attempt to update non existing doc")

    }
    
    func testGetMulipleDocuments() {
        
        // open database
        self.startReplication(replicationConfiguration: Database.ReplicationConfiguration.repeatingBidirectionalReplication(with: URL(string: urlDatabase)!))

        // Add documents to database
        var docs = [Document]()

        let docHandler = DocumentCRUD()
        docHandler.setDatabase(database)
        
        for _ in 0...2 {
            let docId: String! = "DOC_TEST_"+Document.idFactory()
            let document: Document = docHandler.createTestDocument(docId: docId)
            docs.append(document)
        }

        for doc in docs {
            docHandler.addDocumentToDatabase(doc)
        }
        
        // Add document that is not in database
        docs.append(Document())
        
        // Fetch
        docHandler.getDocuments(docs)
        XCTAssertEqual(docHandler.fetchedDocs.count,3)
        XCTAssertNotNil(docHandler.error, "Error was not generated on attempt to fetch non existing doc")

    }
    
    func testDocumentAtatchmentTextFile() {

        // Create text file to be attached to document
        let str = "Super long string here"
        let attachmentLen = str.count
        let attachmentName = "output.txt"
        
        let filename = getDocumentsDirectory().appendingPathComponent(attachmentName)
        
        do {
            try str.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            print("failed to write file")
        }
        
        // Attach this file to document
        let data = str.data(using: .utf8)!
        
        let attachment = DocumentAttachment(name: filename.absoluteString, contentType: "text/plain", data: data)
        
        // open database
        self.startReplication(replicationConfiguration: Database.ReplicationConfiguration.repeatingBidirectionalReplication(with: URL(string: urlDatabase)!))
        
        // create document
        let docId: String! = "DOC_TEST_"+Document.idFactory()
        print("testDocumentAtatchmentTextFile docId: \(docId)")
        
        // Add document
        let docHandler = DocumentCRUD()
        docHandler.setDatabase(database)
        
        let document: Document = docHandler.createTestDocument(docId: docId)
        document.attachments.append(attachment)
        
        docHandler.addDocumentToDatabase(document)
        
        // Verify document attachment
        XCTAssertEqual(document.id, docHandler.fetchedDoc.id, "Updated document id did not match")

        docHandler.getDocument(document)
        XCTAssertEqual(1, docHandler.fetchedDoc.attachments.count, "Updated document did not contain expected number of attachments")
        XCTAssertEqual(attachmentLen, docHandler.fetchedDoc.attachments[0].data.count, "Document string len does not match")
        XCTAssertTrue(docHandler.fetchedDoc.attachments[0].name.contains(attachmentName), "Attachment name is wrong")

    }
    
    // Description:
    // Add image attachment to document
    // image was added to application bundle
    func testDocumentAtatchmentImageFile() {
        
        let attachmentUrl: URL = Bundle.main.url(forResource: "qaImage0", withExtension: "jpg")!
  
        let data = try? Data(contentsOf: attachmentUrl)
        
        let attachment = DocumentAttachment(name: attachmentUrl.absoluteString, contentType: "image/jpeg", data: data!)
        
        // open database
        self.startReplication(replicationConfiguration: Database.ReplicationConfiguration.repeatingBidirectionalReplication(with: URL(string: urlDatabase)!))
        
        // create document
        let docId: String! = "DOC_TEST_"+Document.idFactory()
        print("testDocumentAtatchmentImageFile docId: \(docId)")
        
        // Add document
        let docHandler = DocumentCRUD()
        docHandler.setDatabase(database)
        
        let document: Document = docHandler.createTestDocument(docId: docId)
        document.attachments.append(attachment)
        
        docHandler.addDocumentToDatabase(document)
        
        // Verify document attachment
        XCTAssertEqual(document.id, docHandler.fetchedDoc.id, "Updated document id did not match")
        
        docHandler.getDocument(document)
        XCTAssertEqual(1, docHandler.fetchedDoc.attachments.count, "Updated document did not contain expected number of attachments")
        XCTAssertEqual(data?.count, docHandler.fetchedDoc.attachments[0].data.count, "Attachment size does not match")
        XCTAssertTrue(docHandler.fetchedDoc.attachments[0].name.contains("qaImage0.jpg"), "Attachment name is wrong")
        
    }
    
}
