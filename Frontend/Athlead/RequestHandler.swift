//
//  RequestHandler.swift
//  Athlead
//
//  Created by Wichmann, Jan on 18.12.24.
//
import Foundation

// Manual cookie storage with persistence
private var manualCookieStorage: [String: String] = [:]

// File path for storing cookies using FileManager
private let cookiesFilePath: URL = {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    return documentsDirectory.appendingPathComponent("PersistentCookies.json")
}()


func clearCookies() {
    manualCookieStorage.removeAll()
}

func getCookieFilePath() -> URL {
    return cookiesFilePath
}

// Load cookies from file at app launch
func loadPersistentCookies() {
    do {
        let data = try Data(contentsOf: cookiesFilePath)
        let savedCookies = try JSONDecoder().decode([String: String].self, from: data)
        manualCookieStorage = savedCookies
    } catch {
        print("Failed to load cookies: \(error)")
    }
}

// Save cookies to file
func savePersistentCookies() {
    do {
        let data = try JSONEncoder().encode(manualCookieStorage)
        try data.write(to: cookiesFilePath)
    } catch {
        print("Failed to save cookies: \(error)")
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
        } else {
            print("No manually stored cookies for \(url.host ?? "unknown host").")
        }
    }
    
    
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
                    savePersistentCookies()
                } else {
                    print("No cookies received.")
                }
            }
            
            continuation.resume(returning: .success(response, data))
        }
        task.resume()
    }
}

func fetch<T: Codable>(
    _ urlString: String,
    _ responseType: T.Type,
    _ method: String = "GET",
    _ cookies: [String: String]? = nil,
    _ body: Encodable? = nil,
    _ completion: @escaping (MyResult<T, Error>) -> Void
) {
    guard let url = URL(string: "\(apiURL)/\(urlString)") else {
        completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: nil)))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = method;
    request.setValue("application/json", forHTTPHeaderField: "Content-Type");
    if method != "GET" && body != nil {
        do {
            request.httpBody = try JSONEncoder().encode(body.unsafelyUnwrapped);
        } catch { print("Could not encode body: \(error)"); }
    }
    
    if let cookieHeader = manualCookieStorage[url.host ?? ""] {
        request.addValue(cookieHeader, forHTTPHeaderField: "Cookie")
    }
    
    let task = sharedSession.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -1, userInfo: nil)))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(NSError(domain: "Response error", code: -1, userInfo: nil)))
            return
        }
        
        if httpResponse.statusCode != 200 {
            completion(.failure(NSError(domain: "Response error", code: httpResponse.statusCode, userInfo: nil)))
            return
        }
        
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            
            if let headerFields = httpResponse.allHeaderFields as? [String: String] {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
                
                if !cookies.isEmpty {
                    for cookie in cookies {
                        if let name = cookie.name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                           let value = cookie.value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                            manualCookieStorage[url.host ?? ""] = "\(name)=\(value)"
                        }
                    }
                    savePersistentCookies()
                }
            }
            completion(.success(decodedData))
        } catch {
            completion(.failure(error))
        }
    }
    
    task.resume()
}


