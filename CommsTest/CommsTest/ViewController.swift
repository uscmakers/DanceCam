//
//  ViewController.swift
//  CommsTest
//
//  Created by Irith Katiyar on 10/21/24.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        sendData()
    }
    
    func sendData() {
        guard let url = URL(string: "http://0.0.0.0:5000/api/data") else { return }

        // Create a URLRequest object
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Add headers (e.g., Content-Type for JSON)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create the body data
        let data: [String: Any] = [
            "topic": "Test",
            "message": "This is a test message"
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


}

