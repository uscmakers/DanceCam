//
//  Communcation.swift
//  DanceCam-iOS
//
//  Created by Abby Farhat on 11/18/24.
//

import Foundation

func sendData(duty1: Int, duty2: Int, duty3: Int, duty4: Int) {
    guard let url = URL(string: "http://172.20.10.2:8000/move") else { return }
    
    // Create a URLRequest object
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // Add headers (e.g., Content-Type for JSON)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Create the body data
    let data: [String: Any] = [
        "duty1": duty1,
        "duty2": duty2,
        "duty3": duty3,
        "duty4": duty4,
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
