// WebSocketManager.swift
import Foundation
import Combine

enum ConnectionState {
    case disconnected, connecting, connected, paired
}

struct Robot: Identifiable, Decodable {
    let id: String
    let createdAt: TimeInterval
    let clientType: String
}

class WebSocketManager: ObservableObject {
    static let socketEnabled = false

    @Published var state: ConnectionState = .disconnected
    @Published var availableRobots: [Robot] = []
    var webSocketTask: URLSessionWebSocketTask?
    
    init() {
        if (WebSocketManager.socketEnabled) { connect() }
        else { state = .paired }
    }
    
    func connect() {
        state = .connecting
        let url = URL(string: "ws://producti-bunserverloadba-fa9cd61bac9251c5.elb.us-west-2.amazonaws.com/ws?clientType=user")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        state = .connected
        receive()
    }
    
    func receive() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                DispatchQueue.main.async { self.state = .disconnected }
            case .success(let message):
                if case .string(let text) = message { self.handleMessage(text) }
                self.receive()
            }
        }
    }
    
    func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        if type == "host_listUsers", let list = json["data"] as? [[String: Any]] {
            let robots = list.filter { ($0["clientType"] as? String) == "robot" }
                .compactMap { dict -> Robot? in
                    if let id = dict["id"] as? String,
                       let createdAt = dict["createdAt"] as? TimeInterval {
                        return Robot(id: id, createdAt: createdAt, clientType: "robot")
                    }
                    return nil
                }
            DispatchQueue.main.async { self.availableRobots = robots }
        }
        else if type == "host_pairConnect" {
            DispatchQueue.main.async { self.state = .paired }
        }
        else if type == "host_pairDisconnect" {
            DispatchQueue.main.async { self.state = .connected }
        }
    }
    
    func pair(with robotID: String) {
        let message: [String: Any] = ["type": "user_pairConnect", "data": robotID]
        send(message: message)
    }
    
    func disconnectPair() {
        let message: [String: Any] = ["type": "user_pairDisconnect", "data": ""]
        send(message: message)
        DispatchQueue.main.async { self.state = .connected }
    }
    
    func send(message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let json = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(json)) { _ in }
    }
    
    func sendMove(duty1: Int, duty2: Int, duty3: Int, duty4: Int) {
        let msg: [String: Any] = ["type": "client_message", "data": ["duty1": duty1, "duty2": duty2, "duty3": duty3, "duty4": duty4]]
        send(message: msg)
    }
    
    func sendStop() {
        let msg: [String: Any] = ["type": "client_message", "data": ["stop": true]]
        send(message: msg)
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        state = .disconnected
    }
}
