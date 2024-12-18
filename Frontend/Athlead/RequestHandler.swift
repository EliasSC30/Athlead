//
//  RequestHandler.swift
//  Athlead
//
//  Created by Wichmann, Jan on 18.12.24.
//
import Foundation

// Manual cookie storage with persistence
private var manualCookieStorage: [String: String] = [:]

// Keys for UserDefaults
private let cookiesStorageKey = "PersistentCookies"

// Load cookies from UserDefaults at app launch
func loadPersistentCookies() {
    if let savedData = UserDefaults.standard.data(forKey: cookiesStorageKey) {
        do {
            let savedCookies = try JSONDecoder().decode([String: String].self, from: savedData)
            manualCookieStorage = savedCookies
            print("Loaded persistent cookies: \(manualCookieStorage)")
        } catch {
            print("Failed to decode cookies: \(error)")
        }
    } else {
        print("No persistent cookies found.")
    }
}

// Save cookies to UserDefaults
func savePersistentCookies() {
    do {
        let data = try JSONEncoder().encode(manualCookieStorage)
        UserDefaults.standard.set(data, forKey: cookiesStorageKey)
        print("Saved persistent cookies: \(manualCookieStorage)")
    } catch {
        print("Failed to encode cookies: \(error)")
    }
}

enum Result {
    case success(HTTPURLResponse, Data)
    case failure(Error)
}

private var sessionConfiguration: URLSessionConfiguration = {
    let config = URLSessionConfiguration.default
    config.httpShouldSetCookies = false // Disable automatic cookie handling
    return config
}()

private var sharedSession: URLSession = {
    URLSession(configuration: sessionConfiguration)
}()

func executeURLRequestAsync(request: URLRequest) async throws -> Result {
    var request = request // Make the request mutable
    
    // Add manually stored cookies to the request
    if let url = request.url {
        if let cookieHeader = manualCookieStorage[url.host ?? ""] {
            request.addValue(cookieHeader, forHTTPHeaderField: "Cookie")
            print("Manually added cookies to request: \(cookieHeader)")
        } else {
            print("No manually stored cookies for \(url.host ?? "unknown host").")
        }
    }
    
    print("Headers before sending request: \(request.allHTTPHeaderFields ?? [:])")
    
    return try await withCheckedThrowingContinuation { continuation in
        let task = sharedSession.dataTask(with: request) { data, response, error in
            if let error = error {
                continuation.resume(returning: .failure(error))
                return
            }
            
            guard let response = response as? HTTPURLResponse, let data = data else {
                continuation.resume(returning: .failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
                return
            }
            
            // Extract cookies from the response
            if let url = response.url, let headerFields = response.allHeaderFields as? [String: String] {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
                
                if !cookies.isEmpty {
                    for cookie in cookies {
                        if let name = cookie.name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                           let value = cookie.value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                            manualCookieStorage[url.host ?? ""] = "\(name)=\(value)"
                        }
                    }
                    print("Manually stored cookies: \(manualCookieStorage)")
                    savePersistentCookies() // Save cookies persistently
                } else {
                    print("No cookies received.")
                }
            }
            
            continuation.resume(returning: .success(response, data))
        }
        task.resume()
    }
}
