import Foundation


class WebSocketClient: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private let url: URL

    // Shared URLSession for cookie persistence
    override init() {
        guard let url = URL(string: "ws://localhost:8000/ws/b5855ba6-c114-4817-93a3-7bca520f1b11") else {
            fatalError("Invalid WebSocket URL.")
        }
        self.url = url
        self.urlSession = sharedSession
        super.init()
    }

    func connect() {
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        print("WebSocket: Connecting to \(url.absoluteString)...")

    }

    private func listenForMessages() {
        // This is now a simple loop that listens for messages continuously
        webSocketTask?.receive { result in
            switch result {
            case .failure(let error):
                print("WebSocket: Error receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("WebSocket: Received text message: \(text)")
                case .data(let data):
                    print("WebSocket: Received binary message of size \(data.count) bytes")
                @unknown default:
                    print("WebSocket: Received unknown message")
                }
            }

        }
    }

    func sendPing() {
        webSocketTask?.sendPing { error in
            if let error = error {
                print("WebSocket: Ping failed: \(error)")
            } else {
                print("WebSocket: Ping sent successfully")
            }
        }
    }

    func closeConnection() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        print("WebSocket: Connection closed")
    }

    // Handle pings from the server by letting the session auto-respond
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didReceivePingWith completionHandler: @escaping () -> Void) {
        print("WebSocket: Server sent a ping, responding automatically")
        completionHandler()
    }

    // Handle connection status changes
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket: Connection closed. Code: \(closeCode.rawValue), Reason: \(reason.map { String(data: $0, encoding: .utf8) ?? "Unknown" } ?? "None")")
    }
}
