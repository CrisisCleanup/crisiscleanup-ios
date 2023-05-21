import SwiftUI

struct AuthenticateView<ViewModel>: View where ViewModel: AuthenticateViewModelProtocol {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ViewModel

    @State var emailAddress: String = ""
    @State var password: String = ""
    @FocusState var emailHasFocus: Bool
    @FocusState var passwordHasFocus: Bool

    func authenticate() {
        emailHasFocus = false
        passwordHasFocus = false

        if (emailAddress.isBlank) {
            emailHasFocus = true
            return
        }
        if (password.isBlank) {
            passwordHasFocus = true
            return
        }
        viewModel.authenticate(emailAddress, password)
    }


    var body: some View {
        VStack {
            Text("Authenticate, logout, or dismiss")
            TextField("Email", text: $emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .focused($emailHasFocus)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
                .padding([.vertical])
                .onSubmit {
                    authenticate()
                }
            SecureField("Password", text: $password)
                .focused($passwordHasFocus)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
                .padding([.vertical])
                .onSubmit {
                    authenticate()
                }
            Button("Login Debug") {

            }
            .padding()
            Button("Login") {
                authenticate()
            }
            .padding()
            Button("Dismiss") {
                self.presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
        .padding()
    }
}
