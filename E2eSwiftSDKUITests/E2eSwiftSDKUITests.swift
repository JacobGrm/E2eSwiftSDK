//
//  E2eSwiftSDKUITests.swift
//  E2eSwiftSDKUITests
//
//  Created by Kamal Mann on 11/6/17.
//  Copyright © 2017 General Electric. All rights reserved.
//

import XCTest
import E2eSwiftSDK
@testable import PredixSDK

class E2eSwiftSDKUITests: XCTestCase {
    
    let app = XCUIApplication()
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func userLogin(userName: String, userPwd: String){
        
        let usernameTextField = app.textFields["username"]
        usernameTextField.tap()
        usernameTextField.typeText(userName)
        
        let passwordTextField = app.textFields["password"]
        passwordTextField.tap()
        passwordTextField.typeText(userPwd)
        app.otherElements.containing(.navigationBar, identifier:"E2eSwiftSDK.View").children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).matching(identifier: "Button").element(boundBy: 1).tap()
        
    }
    
    func executeTests() {
        app.buttons["Start Tests"].tap()
        
        
    }
    
    func testStartE2eSuit(){

        userLogin(userName: "jacob@ge.com", userPwd: "Test123")
        executeTests()
    }

}
