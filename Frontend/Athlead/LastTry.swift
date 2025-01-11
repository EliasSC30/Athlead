//
//  LastTry.swift
//  Athlead
//
//  Created by Oezcan, Elias on 09.01.25.
//



import Foundation

class WebSocketClient: NSObject, URLSessionWebSocketDelegate {

    var receivedMessages: [String] = []
    private var webSocketTask: URLSessionWebSocketTask?

    private var timer: Timer?
    
    func startListen() {
            // Schedule a repeating timer to call `performTask()` every 5 seconds
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(performTask), userInfo: nil, repeats: true)
            RunLoop.current.add(timer!, forMode: .common)
    }
    
    @objc func performTask() {
        self.listenForMessages()
    }

    func stopListen() {
        timer?.invalidate()
        timer = nil
    }

    func connect(contestId: String, userToken: String) {
        let backgroundQueue = OperationQueue()
        backgroundQueue.qualityOfService = .background
        var request = URLRequest(url: URL(string: "ws://45.81.234.175:8000/ws/\(contestId)")!)
        request.addValue("Upgrade", forHTTPHeaderField: "Connection")
        request.addValue("websocket", forHTTPHeaderField: "Upgrade")
        
        request.addValue("Token=\(userToken)", forHTTPHeaderField: "Cookie")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: backgroundQueue)
        
        webSocketTask = session.webSocketTask(with: request)
    
        
        webSocketTask?.resume()
        startListen()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.receivedMessages.append(text)
                default:
                    print("Received non-string message: \(message)")
                }
                
            case .failure(let error):
                print("WebSocket error: \(error.localizedDescription)")
            }
        }
        print(receivedMessages)
    }

    func send(message: String) {
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }

    // URLSessionWebSocketDelegate - Handle connection events if needed
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket closed with code: \(closeCode.rawValue), reason: \(String(data: reason ?? Data(), encoding: .utf8) ?? "unknown")")
    }
}


