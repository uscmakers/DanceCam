// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject var wsManager = WebSocketManager()
    
    var body: some View {
        Group {
            if wsManager.state == .paired {
                VideoFeed(wsManager: wsManager)
            } else {
                ConnectionView(wsManager: wsManager)
            }
        }
    }
}
