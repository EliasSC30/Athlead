import SwiftUI

struct AboutTheAppView: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // App Header
                Text("About Athlead")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                // App Description
                Text("Athlead is a sports event management app for schools and clubs. It is designed to help you manage your sports events, contests, and participants. The app is designed to be easy to use and intuitive.")
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                
                // Features Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Key Features:")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("• Manage sports events easily")
                    Text("• Organize contests and participants")
                    Text("• Intuitive and user-friendly interface")
                    Text("• Built with SwiftUI and RUST for optimal performance")
                }
                .font(.body)
                
                // Technologies Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Built with:")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("• SwiftUI for the frontend UI")
                    Text("• RUST for efficient backend processing")
                }
                .font(.body)
                
                // Developers Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Developed By:")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("• Elias N. Özcan - Backend Developer")
                    Text("• Jan H. Wichmann - Frontend Developer")
                
                    
                }
                .font(.body)
                
                // Footer Section
                Divider()
                    .padding(.top, 20)
                
                Text("Thank you for using Athlead! We hope it helps streamline your sports event management.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding()
        }
        .navigationBarTitle("About The App", displayMode: .inline)
    }
}
