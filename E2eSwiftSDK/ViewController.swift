//
//  ViewController.swift
//  E2eSwiftSDK
//
//  Created by Kamal Mann on 11/6/17.
//  Copyright © 2017 General Electric. All rights reserved.
//

import UIKit
import PredixSDK

class ViewController: UIViewController, ServiceBasedAuthenticationHandlerDelegate {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var credentialProvider: AuthenticationCredentialsProvider?
    private var authenticationManager: AuthenticationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Creates an authentication manager configuration configured for your UAA instance.  The baseURL, clientId and clientSecret can also be defined in your info.plist if you wish but for simplicity I've added them to the config below.
        var configuration = AuthenticationManagerConfiguration()
        
        var url_uaa : String!
        if let url = Bundle.main.object(forInfoDictionaryKey: "uaa_url") as? String {
            url_uaa = url
        }
        
        configuration.baseURL = URL(string: url_uaa)

        //Create an online handler so that we can tell the authentication manager we want to authenticate online
        let onlineHandler = UAAServiceAuthenticationHandler()
        onlineHandler.authenticationServiceDelegate = self
        
        //Create an authentication manager with our UAA configuration, set UAA as our authorization source, set the online handler so that the manager knows we want to autenticate online
        authenticationManager = AuthenticationManager(configuration: configuration)
        authenticationManager?.authorizationHandler = UAAAuthorizationHandler()
        authenticationManager?.onlineAuthenticationHandler = onlineHandler
        
        //Tell authentication manager we are ready to authenticate, once we call authenticate it will call our delegate with the credential provider
        authenticationManager?.authenticate { status in

            self.updateStatusText(message: "Authentication \(status)")

            if case AuthenticationManager.AuthenticationCompletionStatus.success(let type, let user) = status {
                print("type: \(type), user: \(user)")
                print("Authentication status -> status: \(status)")

                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let secondViewController = storyboard.instantiateViewController(withIdentifier: "second") as! ExecuteTestsViewController
                    secondViewController.title = "Tests"
                    self.navigationController?.pushViewController(secondViewController, animated: true)
                }
            }
        }
        
        self.updateStatusText(message: "Authentication Started")
    }
    
    @IBAction func signInPressed(_ sender: Any) {
        updateStatusText(message: "Authentication credentials received, sending request to UAA")
        //Give the username and password to the credential provider
        credentialProvider?(self.usernameTextField.text ?? "", self.passwordTextField.text ?? "")
    }
    
    public func authenticationHandler(_ authenticationHandler: PredixSDK.AuthenticationHandler, didFailWithError error: Error) {
        updateStatusText(message: "Authentication failed: \(error)")
    }
    
    public func authenticationHandlerProvidedCredentialsWereInvalid(_ authenticationHandler: AuthenticationHandler) {
        updateStatusText(message: "Invalid username and/or password")
    }
    
    func authenticationHandler(_ authenticationHandler: AuthenticationHandler, provideCredentialsWithCompletionHandler completionHandler: @escaping AuthenticationCredentialsProvider) {
        //Set our credential provider so that when we sign in we can pass the username and password from the text fields to the authentication manager
        credentialProvider = completionHandler
    }
    
    private func updateStatusText(message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }
    
}

