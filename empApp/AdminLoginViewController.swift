//
//  AdminLoginViewController.swift
//  empApp
//
//  Created by Arnav Gupta on 17/11/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class AdminLoginViewController: UITableViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // Firestore database reference
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Admin Login"
        
        // Dismiss keyboard on tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter email and password.")
            return
        }
        
        // Authenticate the user
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                self?.showAlert(message: "Login failed: \(error.localizedDescription)")
                return
            }
            
            // Fetch the user role from Firestore
            self?.db.collection("users").whereField("email", isEqualTo: email).getDocuments { querySnapshot, error in
                if let error = error {
                    self?.showAlert(message: "Error fetching user role: \(error.localizedDescription)")
                    return
                }
                
                guard let document = querySnapshot?.documents.first,
                      let role = document.data()["role"] as? String else {
                    self?.showAlert(message: "User role not found.")
                    return
                }
                
                // Check if the user has the 'admin' role
                if role == "admin" {
                    self?.performSegue(withIdentifier: "toAdminPanel", sender: self)
                } else {
                    self?.showAlert(message: "Access denied. Admin role is required.")
                    // Log the user out since they are not an admin
                    do {
                        try Auth.auth().signOut()
                    } catch let signOutError {
                        print("Error signing out: \(signOutError)")
                    }
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
