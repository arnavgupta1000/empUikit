import UIKit
import FirebaseFirestore
import FirebaseAuth
class UsersListViewController: UITableViewController {
    
    var users: [User] = [] // Array to hold user data
    let db = Firestore.firestore() // Firestore reference

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select User"
        fetchUsers()
    }
    
    func fetchUsers() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }

        db.collection("employees").getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }

            // Filter out the current user from the list
            self.users = querySnapshot?.documents.compactMap { doc -> User? in
                let data = doc.data()
                guard let email = data["email"] as? String,
                      let name = data["name"] as? String,
                      email != currentUserEmail else { // Exclude the logged-in user's email
                    return nil
                }
                return User(email: email, name: name)
            } ?? []

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = users[indexPath.row]
        navigateToChat(with: selectedUser)
    }
    
    func navigateToChat(with user: User) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController {
            chatVC.selectedUser = user
            self.navigationController?.pushViewController(chatVC, animated: true)
        }
    }
}
