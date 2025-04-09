//
//  ConnectionView.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 3/3/25.
//


// ConnectionView.swift
import SwiftUI

struct ConnectionView: View {
    @ObservedObject var wsManager: WebSocketManager
    var body: some View {
        NavigationView {
            List(wsManager.availableRobots) { robot in
                Button(robot.id) {
                    wsManager.pair(with: robot.id)
                }
            }
            .navigationTitle("Select Robot")
        }
    }
}
