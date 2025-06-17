import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    let firstName: String
    
    @State private var currentPage = 0
    @State private var selectedOption = ""
    @State private var showingAuthErrorAlert = false
    @State private var navigateToCalendar = false
    @ObservedObject private var authManager = GoogleAuthManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Welcome, \(firstName)!")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 50)
                
                Group {
                    switch currentPage {
                    case 0:
                        QuestionView(
                            question: "What do you want to use Timely for?",
                            optionsWithIcons: [
                                ("Personal", "person"),
                                ("Work", "briefcase"),
                                ("Both", "person.2")
                            ],
                            selectedOption: $selectedOption
                        )
                    case 1:
                        QuestionView(
                            question: "How do you prefer to schedule meetings?",
                            optionsWithIcons: [
                                ("Manually", "hand.tap"),
                                ("Automatically", "sparkles"),
                                ("Mixed", "slider.horizontal.3")
                            ],
                            selectedOption: $selectedOption
                        )
                    case 2:
                        QuestionView(
                            question: "Set up the calendar that will be used to check for existing events?",
                            optionsWithIcons: [
                                ("Google Calendar", "calendar"),
                                ("Exchange Calendar", "tray.and.arrow.down.fill"),
                                ("Outlook Calendar", "envelope.badge")
                            ],
                            selectedOption: $selectedOption
                        )
                    default:
                        Text("End")
                    }
                }
                
                Spacer()
                
                Button(action: {
                    if currentPage == 2 && selectedOption == "Google Calendar" {
                        startGoogleSignIn()
                    } else {
                        goToNextPageOrFinish()
                    }
                }) {
                    Text(currentPage < 2 ? "Next" : "Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedOption.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedOption.isEmpty)
                .alert(isPresented: $showingAuthErrorAlert) {
                    Alert(title: Text("Authentication Failed"), message: Text("Could not sign in with Google."), dismissButton: .default(Text("OK")))
                }
                
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $navigateToCalendar) {
                CalendarManagerView()
            }
        }
    }
    
    private func startGoogleSignIn() {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else {
            print("Root ViewController not found!")
            showingAuthErrorAlert = true
            return
        }

        GoogleAuthManager.shared.signIn(from: rootVC) { token in
            if let token = GoogleAuthManager.shared.accessToken {
                print("Google Access Token: \(token)")
                navigateToCalendar = true
            } else {
                showingAuthErrorAlert = true
            }
        }
    }
    
    private func goToNextPageOrFinish() {
        if currentPage < 2 {
            currentPage += 1
            selectedOption = ""
        } else {
            showOnboarding = false
        }
    }
}

