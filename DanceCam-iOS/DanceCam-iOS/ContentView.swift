import SwiftUI

// MARK: - Main View
struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        VideoFeed()
    }
}
