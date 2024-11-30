import UIKit
import FirebaseFirestore
import FirebaseAuth

class EmployeeRegistrationViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var designationTextField: UITextField!
    @IBOutlet weak var salaryTextField: UITextField!
    @IBOutlet weak var empIDTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    let db = Firestore.firestore()

    @IBAction func registerButtonTapped(_ sender: UIButton) {
        guard let fullName = fullNameTextField.text, !fullName.isEmpty,
              let age = ageTextField.text, !age.isEmpty,
              let address = addressTextField.text, !address.isEmpty,
              let designation = designationTextField.text, !designation.isEmpty,
              let salary = salaryTextField.text, !salary.isEmpty,
              let empID = empIDTextField.text, !empID.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
            } else {
                self.saveEmployeeData(fullName: fullName, age: age, address: address, designation: designation, salary: salary, empID: empID, email: email)
            }
        }
    }

    func saveEmployeeData(fullName: String, age: String, address: String, designation: String, salary: String, empID: String, email: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        db.collection("employees").document(userID).setData([
            "name": fullName,
            "age": age,
            "address": address,
            "designation": designation,
            "salary": salary,
            "empID": empID,
            "email": email
        ]) { error in
            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
            } else {
                self.showAlert(title: "Success", message: "Employee registered successfully!")
            }
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
