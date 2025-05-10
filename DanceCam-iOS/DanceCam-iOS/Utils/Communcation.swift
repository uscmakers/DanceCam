//
//  Communcation.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import Foundation

func sendStopCommand() {
    sendMoveCommand(command:"stop", speed:0)
}

func sendMoveCommand(command: String, speed: Int) {
    guard let url = URL(string: "http://172.20.10.9:8000/move") else { return }
    
    // Create a URLRequest object
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // Add headers (e.g., Content-Type for JSON)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    print("direction")
    print(command)
    print("speed")
    print(speed)
    // Create the body data
    let data: [String: Any] = [
        "command": command,
        "speed": speed,
    ]
    
    // Convert data dictionary to JSON and set to request body
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: data, options: [])
    } catch {
        print("Error serializing JSON: \(error)")
        return
    }
    
    // Create a URLSession task
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
        }
        
        if let data = data {
            let responseString = String(data: data, encoding: .utf8)
            print("Response: \(responseString ?? "")")
        }
    }
    
    // Start the task
    task.resume()
}
