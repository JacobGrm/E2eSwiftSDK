//
//  AssetService.swift
//  E2eSwiftSDKTests
//
//  Created by Grimberg, Jacob (GE Global Research) on 1/29/18.
//  Copyright © 2018 Jacob Grimberg. All rights reserved.
//

import XCTest
import PredixSDK

class AssetServiceTests: XCTestCase {
    
    var urlEndPoint: String!
    var clientId: String!
    var clientSecret: String!
    var validAssets: [[String: Any]]!
    var assetTestId: String!
    var uniqueValue: String!
    
    var authenticator: AuthenticationAsset!
    var configuration: AssetManagerConfiguration!
    var assetManager: AssetManager!
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let assetId = Document.idFactory()
        uniqueValue = Document.idFactory()
        self.assetTestId = assetId
        print("ASSET ID: \(assetId)")
        
        self.validAssets = [
            [
                "uri": "/locomotives/\(assetId)",
                "type": "Diesel-electric",
                "model": "ES44AC",
                "serial_no": "001",
                "emission_tier": "0+",
                "fleet": "/fleets/up-1",
                "manufacturer": "/manufacturers/GE",
                "engine": "/engines/v12-1",
                "installedOn": "01/12/2005",
                "dateIso": "2005-12-01T13:15:31Z",
                "qaField": uniqueValue,
                "hqLatLng": [
                    "lat": 33.914605,
                    "lng": -117.253374
                ]
            ]
        ]
        
        // Do authentication first
        Utilities.predixSyncURL = Utilities.retreivePredixSyncURLFromConfig(location: .infoplist)
        urlEndPoint = Utilities.predixSyncURL!.absoluteString
        
        clientId = Utilities.configValueForKey("client_id_asset") as! String
        clientSecret = Utilities.configValueForKey("client_secret_asset") as! String
        
        authenticator = AuthenticationAsset()
        
        authenticator.authenticate(urlEndPoint, clientId: clientId, clientSecret: clientSecret)
        
        configuration = AssetManagerConfiguration(instanceId: "444e8d54-9c4b-4bb1-b364-b43aeab1eb71")
        assetManager = AssetManager(configuration: configuration)

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAssetServiceFetchAllAsset() {
        
        // Create asset
        let assetFetchExpectation = self.expectation(description: #function)
        assetManager.fetchAssets(assetType: "locomotives", query: AssetQuery(), completionHandler: { (asset, status) in

            switch status {
                case .success:
                    XCTAssertTrue(asset!.results.count > 1, "Number of fetched assets is wrong")
                
                case .failed(let error):
                    XCTFail("Unable to fetch assets testAssetServiceFetchAllAsset with error:  \(error.localizedDescription)")
            }
            assetFetchExpectation.fulfill()
        })
        self.waitForExpectations(timeout: 20, handler: nil)
        
    }
    
    func testAssetServiceCreateAsset() {
        
        // Create asset
        let assetCreationExpectation = self.expectation(description: #function)
        assetManager.createAssets(jsonAssets: validAssets, completionHandler: { (asset, status) in
            
            switch status {
                case .success:
                    XCTAssertEqual(asset!.results.count, 1)
                case .failed(let error):
                    XCTFail("Unable to create assets testAssetServiceCreateAsset with error:  \(error.localizedDescription)")
            }
            assetCreationExpectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 20, handler: nil)
        
        // Fetch created asset
        var query = AssetQuery()
        query.fields = "uri,emission_tier,fleet"
        if let fltr = assetTestId {
            query.filter = "uri=/locomotives/\(fltr)"
            print("This is filter: \(String(describing: query.filter))")
        }
        query.pageSize = 10
        let assetFetchExpectation = self.expectation(description: #function)
        assetManager.fetchAssets(assetType: "locomotives", query: query, completionHandler: { (asset, status) in
            
            switch status {
                case .success:
                    print("Asset testAssetServiceCreateAsset: \(String(describing: asset))")
                    XCTAssertEqual(asset!.results.count, 1)
                    XCTAssertEqual(asset!.results.first!.count, 3)

                case .failed(let error):
                    XCTFail("Unable to fetch assets testAssetServiceCreateAsset with error:  \(error.localizedDescription)")
            }
            assetFetchExpectation.fulfill()
        })
        self.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testAssetServiceFetchSingleAssetFilteredByField() {
        
        // Create asset
        let assetCreationExpectation = self.expectation(description: #function)
        assetManager.createAssets(jsonAssets: validAssets, completionHandler: { (asset, status) in
            
            switch status {
            case .success:
                XCTAssertEqual(asset!.results.count, 1)
            case .failed(let error):
                XCTFail("Unable to create assets testAssetServiceCreateAsset with error:  \(error.localizedDescription)")
            }
            assetCreationExpectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 20, handler: nil)
        
        // Fetch asset
        var query = AssetQuery()
        query.fields = "model,installedOn"
        query.filter = "qaField=\(uniqueValue!)"
        query.pageSize = 10
        
        let assetFetchExpectation = self.expectation(description: #function)
        assetManager.fetchAssets(assetType: "locomotives", query: query, completionHandler: { (asset, status) in
            
            switch status {
                case .success:
                    print("Asset fetched description: \(String(describing: asset))")
                    XCTAssertEqual(asset!.results.count, 1)
                    XCTAssertEqual(asset!.results.first!.count, 2)
                    XCTAssertEqual(asset!.results[0]["installedOn"]! as! String, "01/12/2005")
                    XCTAssertEqual(asset!.results[0]["model"]! as! String, "ES44AC")
                
                case .failed(let error):
                    print("Error Fetching asset: \(error)")
                    XCTAssertEqual("Unable to fetch assets", error.localizedDescription)
            }
            assetFetchExpectation.fulfill()
        })
        self.waitForExpectations(timeout: 20, handler: nil)
        
    }

    // When no field specified in AssetQuery, all fields should be fetched
    func testAssetServiceFetchSingleAssetFieldNotSpecified() {
        
        // Create asset
        let assetCreationExpectation = self.expectation(description: #function)
        assetManager.createAssets(jsonAssets: validAssets, completionHandler: { (asset, status) in
            
            switch status {
            case .success:
                XCTAssertEqual(asset!.results.count, 1)
            case .failed(let error):
                XCTFail("Unable to create assets testAssetServiceFetchSingleAssetFieldNotSpecified with error:  \(error.localizedDescription)")
            }
            assetCreationExpectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 20, handler: nil)
        
        // Fetch asset
        var query = AssetQuery()
        query.filter = "qaField=\(uniqueValue!)"
        query.pageSize = 10
        
        let assetFetchExpectation = self.expectation(description: #function)
        assetManager.fetchAssets(assetType: "locomotives", query: query, completionHandler: { (asset, status) in
            
            switch status {
            case .success:
                print("Asset fetched description: \(String(describing: asset))")
                XCTAssertEqual(asset!.results.count, 1)
                // 12 is total count of fields in asset
                XCTAssertEqual(asset!.results.first!.count, 12)
                XCTAssertEqual(asset!.results[0]["installedOn"]! as! String, "01/12/2005")
                XCTAssertEqual(asset!.results[0]["model"]! as! String, "ES44AC")
                
            case .failed(let error):
                print("Error Fetching asset: \(error)")
                XCTAssertEqual("Unable to fetch assets", error.localizedDescription)
            }
            assetFetchExpectation.fulfill()
        })
        self.waitForExpectations(timeout: 20, handler: nil)
        
    }

    func testAssetServiceFetchNonExistingAsset() {
        
        // Fetch asset
        var query = AssetQuery()
        query.fields = "uri"
        query.filter = "qaField=test_non_exising_asset"
        query.pageSize = 10
        
        let assetFetchExpectation = self.expectation(description: #function)
        assetManager.fetchAssets(assetType: "locomotives", query: query, completionHandler: { (asset, status) in
            
            switch status {
                case .success:
                    print("Asset fetched description: \(String(describing: asset))")
                    XCTAssertEqual(asset!.results.count, 0)
                
                case .failed(let error):
                    print("Error Fetching asset: \(error)")
                    XCTAssertEqual("Unable to fetch assets", error.localizedDescription)
            }
            assetFetchExpectation.fulfill()
        })
        self.waitForExpectations(timeout: 20, handler: nil)
        
    }

    func testAssetServiceFetchAssetNonExistingField() {
        
        // Fetch asset
        var query = AssetQuery()
        query.filter = "Field-not-there=123456"
        
        let assetFetchExpectation = self.expectation(description: #function)
        assetManager.fetchAssets(assetType: "locomotives", query: query, completionHandler: { (asset, status) in
            
            switch status {
            case .success:
                print("Asset fetched description: \(String(describing: asset))")
                XCTAssertEqual(asset!.results.count, 0)
                
            case .failed(let error):
                print("Error Fetching asset: \(error)")
                XCTAssertEqual("Unable to fetch assets", error.localizedDescription)
            }
            assetFetchExpectation.fulfill()
        })
        self.waitForExpectations(timeout: 20, handler: nil)
        
    }

    func testAssetServiceFetchAllAssets() {
        
        // Fetch assets
        let query = AssetQuery()
        
        let assetFetchExpectation = self.expectation(description: #function)
        assetManager.fetchAssets(assetType: "locomotives", query: query, completionHandler: { (asset, status) in
            
            switch status {
                case .success:
                    print("Asset fetched description: \(String(describing: asset))")
                    print("Asset fetched count: \(String(describing: asset!.results.count))")
                    let result = asset!.results.count > 1
                    XCTAssertTrue(result, "Error fetching assets")
                
                case .failed(let error):
                    print("Error Fetching asset: \(error)")
                    XCTAssertEqual("Unable to fetch assets", error.localizedDescription)
            }
            assetFetchExpectation.fulfill()
        })
        self.waitForExpectations(timeout: 20, handler: nil)
        
    }
    
    func testAssetServiceModifyAsset() {
        
        let assetOriginalId = Document.idFactory()
        
        let assetOriginal = [
            [
                "uri": "/locomotives/\(assetOriginalId)",
                "type": "Diesel-electric",
                "model": "ES44AC",
                "serial_no": "001",
                "emission_tier": "0+",
                "fleet": "/fleets/up-1",
                "manufacturer": "/manufacturers/GE",
                "engine": "/engines/v12-1",
                "installedOn": "01/12/2005",
                "dateIso": "2005-12-01T13:15:31Z",
                "qaField": "something",
                "hqLatLng": [
                    "lat": 33.914605,
                    "lng": -117.253374
                ]
            ]
        ]

        
        // Create asset
        let assetCreationExpectation = self.expectation(description: #function)
        assetManager.createAssets(jsonAssets: assetOriginal, completionHandler: { (asset, status) in
            
            switch status {
                case .success:
                    print("Asset created testAssetServiceModifyAsset: \(assetOriginalId)")
                    XCTAssertEqual(asset!.results.count, 1)
                case .failed(let error):
                    print("Unable to create asset testAssetServiceCreateAsset: \(error)")
                    XCTAssertEqual("Unable to create asset testAssetServiceCreateAsset", error.localizedDescription)
            }
            assetCreationExpectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 20, handler: nil)
        
        // Modify asset
        let modifiedValue = Document.idFactory()
        print("Modified Value: \(modifiedValue)")
        
        let assetModified = [
            [
                "uri": "/locomotives/\(assetOriginalId)",
                "type": "Diesel-electric",
                "model": "ES44AC",
                "serial_no": "001",
                "emission_tier": "0+",
                "fleet": "/fleets/up-1",
                "manufacturer": "/manufacturers/GE",
                "engine": "/engines/v12-1",
                "installedOn": "01/12/2005",
                "dateIso": "2005-12-01T13:15:31Z",
                "qaField": modifiedValue,
                "hqLatLng": [
                    "lat": 33.914605,
                    "lng": -117.253374
                ]
            ]
        ]
        
        let assetModifyExpectation = self.expectation(description: #function)
        assetManager.createAssets(jsonAssets: assetModified, completionHandler: { (asset, status) in
            
            switch status {
            case .success:
                print("Asset modify testAssetServiceModifyAsset: \(assetOriginalId)")
                XCTAssertEqual(asset!.results.count, 1)
            case .failed(let error):
                print("Unable to create modify testAssetServiceCreateAsset: \(error)")
                XCTAssertEqual("Unable to modify asset testAssetServiceCreateAsset", error.localizedDescription)
            }
            assetModifyExpectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 20, handler: nil)
        
        
        // Fetch modified asset
        var query = AssetQuery()
        query.fields = "uri,qaField"
        query.filter = "qaField=\(modifiedValue)"
        query.pageSize = 10
        let assetFetchExpectation = self.expectation(description: #function)
        assetManager.fetchAssets(assetType: "locomotives", query: query, completionHandler: { (asset, status) in

            switch status {
                case .success:
                    XCTAssertEqual(asset!.results.count, 1)
                    XCTAssertEqual(asset!.results[0]["qaField"]! as! String, modifiedValue)

                case .failed(let error):
                    print("Error Fetching asset: \(error)")
                    XCTAssertEqual("Unable to fetch assets", error.localizedDescription)
            }
            assetFetchExpectation.fulfill()
        })
        self.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testAssetServiceCreateAssetNoUriProvided() {
        
        // use this unique value to search for asset in case it was created
        let uniqueValue = Document.idFactory()
        print("Unique value: \(uniqueValue)")
        
        let assetsNoUri = [
            [
                "type": "Diesel-electric",
                "model": "ES44AC",
                "serial_no": "001",
                "emission_tier": "0+",
                "fleet": "/fleets/up-1",
                "manufacturer": "/manufacturers/GE",
                "engine": "/engines/v12-1",
                "installedOn": "01/12/2005",
                "dateIso": "2005-12-01T13:15:31Z",
                "qaField": uniqueValue
            ]
        ]
        
        // Create asset
        let assetCreationExpectation = self.expectation(description: #function)
        assetManager.createAssets(jsonAssets: assetsNoUri, completionHandler: { (asset, status) in
            
            switch status {
            case .success:
                XCTAssertTrue((asset != nil), "Asset creation should fail")
            case .failed(let error):
                print("Unable to create asset testAssetServiceCreateAssetNoUriProvided: \(error)")
                XCTAssertFalse(error.localizedDescription.isEmpty, "Asset creation should fail")
            }
            assetCreationExpectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 20, handler: nil)
        
    }
}
