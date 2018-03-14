//
//  ExecuteTestsViewController.swift
//  E2eSwiftSDK
//
//  Created by Grimberg, Jacob (GE Global Research) on 11/8/17.
//  Copyright © 2017 Jeremy Osterhoudt. All rights reserved.
//

import UIKit
//import PredixSDK

class ExecuteTestsViewController: UIViewController {
    
    @IBOutlet weak var testButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("Second view controller loaded")

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    //MARK: Actions
    
    @IBAction func runTests(_ sender: UIButton) {
        
        print("Test execution started...")
        
//        OpenUrlServiceTest.openUrlService()
        
//        let auth = AuthenticationTest()
//        auth.authenticate()
        
//        let db = DatabaseCRUDTests(id: "pm", location: URL(string: "https://98h7v1.run.aws-usw02-pr.ice.predix.io")!)
//
//        print(db)
        
    }
    
}
