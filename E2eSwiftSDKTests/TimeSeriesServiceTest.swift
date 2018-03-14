//
//  TimeSeriesServiceTest.swift
//  E2eSwiftSDKTests
//
//  Created by Grimberg, Jacob (GE Global Research) on 2/26/18.
//  Copyright © 2018 Jacob Grimberg. All rights reserved.
//

import XCTest
import PredixSDK

class TimeSeriesServiceTest: XCTestCase {
    
    var authenticator: AuthenticationTimeSeries!
    let endPointUrl = "https://cc3b0275-8b82-479a-9854-80be7a7eea82.predix-uaa.run.aws-usw02-pr.ice.predix.io"
    let clientId = "jacob_ts"
    let clientSecret = "Test123"
    
    let tagsArray = ["Compressor-1C5E05EC5D804EB7B2AAFA020DECB68:CompressionRatio",
                     "Compressor-45364A00536C4F88B98A5E81797B748D:CompressionRatio"]
    
    var timeSeriesManager: TimeSeriesManager!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // Do authentication
        authenticator = AuthenticationTimeSeries()
        authenticator.authenticate(endPointUrl, clientId: clientId, clientSecret: clientSecret)
        
        // Create manager for fetching data
        let config: TimeSeriesManagerConfiguration = TimeSeriesManagerConfiguration(predixZoneId: "20394df9-8b24-4168-8d47-99fea2b73b2a")
        self.timeSeriesManager = TimeSeriesManager(configuration: config)

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFetchTags() {
        
        let fetchTagsExpectation = self.expectation(description: #function)
        self.timeSeriesManager?.fetchTagNames { (tags, error) in
                if tags.count > 0 {
                    print("Success testFetchTags: \(tags.joined(separator: ","))")
                    XCTAssertGreaterThan(tags.count, 2)
                    XCTAssertEqual(tags[0],self.tagsArray[0])
                    XCTAssertEqual(tags[1],self.tagsArray[1])
                } else if let anError = error {
                    print("Error testFetchTags: \(anError)")
                    XCTFail("Error testFetchTags:  \(anError.localizedDescription)")
                } else {
                    //We didn't get any tags and there were't any errors!
                    print("No tags available")
                    XCTFail("Tags should be there testFetchTags!")
                }
            fetchTagsExpectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 10, handler: nil)

    }
    
    
    func testFetchDataPointsNonExistingTags() {
        
        let dataPointsRequest = DataPointRequest(tagNames: ["tag1","tag2"], timeRange: TimeRange(0...))

        let fetchDataPointsExpectation = self.expectation(description: #function)
        self.timeSeriesManager?.fetchDataPoints(request: dataPointsRequest) { (results, error) in
            if let anError = error {
                XCTFail("Error testFetchDataPoints:  \(anError.localizedDescription)")
            } else if let dataPoints = results?.dataPoints {
                for dataPoint in dataPoints {
                    XCTAssertEqual(dataPoint.results!.first!.values!.count,0)
                }
            } else {
                XCTFail("Unknown issue fetching data points")
            }
            fetchDataPointsExpectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testFetchDataPointsSingleTag() {
        
        let dataPointsRequest = DataPointRequest(tagNames: [self.tagsArray[1]], timeRange: TimeRange(0...))
        
        let fetchDataPointsExpectation = self.expectation(description: #function)
        self.timeSeriesManager?.fetchDataPoints(request: dataPointsRequest) { (results, error) in
            if let anError = error {
                XCTFail("Error testFetchDataPoints:  \(anError.localizedDescription)")
            } else if let dataPoints = results?.dataPoints {
                for dataPoint in dataPoints {
                    XCTAssertEqual(dataPoint.tagName, self.tagsArray[1])
                    XCTAssertGreaterThan(dataPoint.results!.first!.values!.count, 0)
                }
            } else {
                XCTFail("Unknown issue fetching data points")
            }
            fetchDataPointsExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    
    func testFetchDataPointsTimeRangeSingleTag() {
        
        // TimeRange - 02/28/1970 to 02/28/2018
        let dataPointsRequest = DataPointRequest(tagNames: [self.tagsArray[0]], timeRange: TimeRange(2678400...1519858535))
        
        let fetchDataPointsExpectation = self.expectation(description: #function)
        self.timeSeriesManager?.fetchDataPoints(request: dataPointsRequest) { (results, error) in
            if let anError = error {
                XCTFail("Error testFetchDataPoints:  \(anError.localizedDescription)")
            } else if let dataPoints = results?.dataPoints {
                for dataPoint in dataPoints {
                    XCTAssertEqual(dataPoint.tagName, self.tagsArray[0])
                    XCTAssertGreaterThan(dataPoint.results!.first!.values!.count, 0)
                }
            } else {
                XCTFail("Unknown issue fetching data points")
            }
            fetchDataPointsExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }
    

    func testFetchSingleTagGroupedDataPoints() {

        let tag = TagQuery(name: self.tagsArray[1], groups: [TagGroup(name: "quality")])
        let dataPointsRequest = DataPointRequest(tagQuerys: [tag], timeRange: TimeRange(0...))
        
        let fetchDataPointsExpectation = self.expectation(description: #function)
        self.timeSeriesManager?.fetchDataPoints(request: dataPointsRequest) { (results, error) in
            if let anError = error {
                XCTFail("Error testFetchDataPoints:  \(anError.localizedDescription)")
            } else if let dataPoints = results?.dataPoints {
                for dataPoint in dataPoints {
                    XCTAssertEqual(dataPoint.tagName, self.tagsArray[1])
                    XCTAssertGreaterThan(dataPoint.results!.first!.values!.count, 0)
                }
            } else {
                XCTFail("Unknown issue fetching data points")
            }
            fetchDataPointsExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    
    // DE66786
    func testFetchSingleTagGroupedDataPointsWithDefaultDataPointRequestArgument() {
        
        let tag = TagQuery(name: self.tagsArray[1], groups: [TagGroup(name: "quality")], order: .descending)
//        let dataPointsRequest = DataPointRequest(tagQuerys: [tag], timeRange: TimeRange(0...))
        let dataPointsRequest = DataPointRequest(tagQuerys: [tag])

        let fetchDataPointsExpectation = self.expectation(description: #function)
        self.timeSeriesManager?.fetchDataPoints(request: dataPointsRequest) { (results, error) in
            if let anError = error {
                XCTFail("Error testFetchDataPoints:  \(anError.localizedDescription)")
            } else if let dataPoints = results?.dataPoints {
                for dataPoint in dataPoints {
                    XCTAssertEqual(dataPoint.tagName, self.tagsArray[1])
                    XCTAssertGreaterThan(dataPoint.results!.first!.values!.count, 0)
                }
            } else {
                XCTFail("Unknown issue fetching data points")
            }
            fetchDataPointsExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    // Status code 400 expected with invalid group name
    func testFetchSingleTagGroupedDataPointsInvalidGroupName() {
        
        let invalidGroupName = "quality123"
        
        let tag = TagQuery(name: self.tagsArray[1], groups: [TagGroup(name: invalidGroupName)], order: .descending)
        let dataPointsRequest = DataPointRequest(tagQuerys: [tag], timeRange: TimeRange(0...))
        
        let fetchDataPointsExpectation = self.expectation(description: #function)
        self.timeSeriesManager?.fetchDataPoints(request: dataPointsRequest) { (results, error) in
            if let anError = error {
                print("Error testFetchSingleTagGroupedDataPointsInvalidGroupName:  \(anError.localizedDescription)")
                XCTAssert(anError.localizedDescription.contains("400"))
            } else if let dataPoints = results?.dataPoints {
                for _ in dataPoints {
                    XCTFail("Error should occur with invalid group name testFetchSingleTagGroupedDataPointsInvalidGroupName")
                }
            } else {
                XCTFail("Unknown issue fetching data points")
            }
            fetchDataPointsExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testFetchDataPointsMultipleTags() {
        
        let dataPointsRequest = DataPointRequest(tagNames: [self.tagsArray[0], self.tagsArray[1]], timeRange: TimeRange(0...))
        
        let fetchDataPointsExpectation = self.expectation(description: #function)
        self.timeSeriesManager?.fetchDataPoints(request: dataPointsRequest) { (results, error) in
            if let anError = error {
                XCTFail("Error testFetchDataPoints:  \(anError.localizedDescription)")
            } else if let dataPoints = results?.dataPoints {
                for dataPoint in dataPoints {
                    
                    let tagName = dataPoint.tagName
                    if tagName == self.tagsArray[0] {
                        print("Tag name 1 expected: \(dataPoint.tagName)")
                        XCTAssertGreaterThan(dataPoint.results!.first!.values!.count, 0)

                    } else if tagName == self.tagsArray[1] {
                        print("Tag name 2 expected: \(dataPoint.tagName)")
                        XCTAssertGreaterThan(dataPoint.results!.first!.values!.count, 0)

                    } else {
                        XCTFail("This tag should not be fetched: \(tagName)")
                    }
                }
            } else {
                XCTFail("Unknown issue fetching data points")
            }
            fetchDataPointsExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }
    
    
    //  Reason test is failing:
    //  our call to fetchLatestDataPoints(..) returns 0 records
    //  But records are there.
    //  Result is consistent with PredixToolKit and Postman meaning they also return 0 records.
    //  Call is POST https://time-series-store-predix.run.aws-usw02-pr.ice.predix.io/v1/datapoints/latest
    //  If start and end time provided - records are retrieved, but with "latest" you don't have to do that
    //  TimeSeries site might have changed something. Jeremy will look into it
    func testFetchLatestDataPoints() {
        
        let latestDataPointRequest = LatestDataPointRequest(tagNames: [self.tagsArray[0],self.tagsArray[1]])
        
        let fetchLatestDataPointsExpectation = self.expectation(description: #function)
        self.timeSeriesManager?.fetchLatestDataPoints(request: latestDataPointRequest) { (results, error) in
            if let anError = error {
                XCTFail("Error testFetchLatestDataPoints:  \(anError.localizedDescription)")
            } else if let dataPoints = results?.dataPoints {
                for dataPoint in dataPoints {

                    let tagName = dataPoint.tagName
                    if tagName == self.tagsArray[0] {
                        XCTAssertGreaterThan(dataPoint.results!.first!.values!.count, 0)
                    } else if tagName == self.tagsArray[1] {
                        XCTAssertGreaterThan(dataPoint.results!.first!.values!.count, 0)

                    } else {
                        XCTFail("This tag should not be fetched: \(tagName)")
                    }
                }
            } else {
                XCTFail("Unknown issue fetching data points")
            }
            fetchLatestDataPointsExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testAggregationRequest() {
        
        let tagAggregation = TagAggregation(type: .average, sampling: AggregationSampling(value: "30", unit: .seconds))
        let tag = TagQuery(name: self.tagsArray[0], groups: [TagGroup(name: "quality")], aggregations: [tagAggregation], limit: 4, order: .descending)
        let dataPointsRequest = DataPointRequest(tagQuerys: [tag], timeRange: TimeRange(2678400...1519858535))
        
        let fetchDataPointsExpectation = self.expectation(description: #function)
        self.timeSeriesManager?.fetchDataPoints(request: dataPointsRequest) { (results, error) in
            if let anError = error {
                XCTFail("Error testFetchDataPoints:  \(anError.localizedDescription)")
            } else if let dataPoints = results?.dataPoints {
                for dataPoint in dataPoints {
                    XCTAssertEqual(dataPoint.tagName, self.tagsArray[0])
                    XCTAssertGreaterThan(dataPoint.results!.first!.values!.count, 0)
                }
            } else {
                XCTFail("Unknown issue fetching data points")
            }
            fetchDataPointsExpectation.fulfill()
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }


}
