//
//  DataStore.swift
//  Athlead
//
//  Created by Oezcan, Elias on 01.12.24.
//

import Foundation

var apiURL: String {
    get {
        #if targetEnvironment(simulator)
                return "http://localhost:8000"
        #else
                return "http://45.81.234.175:8000"
        #endif
    }
}

struct RegisterData: Encodable {
    let email: String
    let password: String
    
    let first_name: String
    let last_name: String
    let phone: String
    let grade: String?
    let birth_year: String?
    let role: String
}

struct RegisterResponse: Decodable {
    let data: String
    let status: String
    let id: String
}

struct LoginData: Encodable {
    let email: String
    let password: String?
    let token: String?
}

struct LoginResponse: Decodable {
  //  let data: String
  //  let id: String
    let status: String
}

struct ResultInfo {
    let name: String
    let metric: Metric
}

// Mock Data Structures
struct Location: Identifiable, Hashable, Decodable {
    let ID: String
    let NAME: String
    let CITY: String
    let STREET: String
    let STREETNUMBER: String
    let ZIPCODE: String
    
    var id: String { return self.ID }
}

struct LocationsResponse: Decodable {
    let data: [Location]
    let status: String
}

struct LocationResponse: Decodable {
    let data: Location
    let status: String
}

struct PersonsResponse: Decodable {
    let data: [Person]
    let results: Int
    let status: String
}

struct PersonResponse: Decodable {
    let data: Person
    let status: String
}

struct PersonCreate: Encodable {
    let first_name: String
    let last_name: String
    let email: String
    let phone: String
    let birth_year: String?
    let grade: String?
    let role: String
}

struct PersonCreateResponse: Decodable {
    let data: Person
    let status: String
}

struct Person: Identifiable, Hashable, Decodable {
    let ID : String
    let FIRSTNAME: String
    let LASTNAME: String
    let EMAIL: String
    let PHONE: String
    let BIRTH_YEAR: String?
    let GRADE: String?
    let ROLE: String
    let PICS: Int
    let GENDER: String
    
    var id: String { return self.ID }
}

struct Participant: Codable, Identifiable {
    let id: String
    let f_name: String
    let l_name: String
    let email: String
    let phone: String
    let grade: String?
    let birth_year: String?
    let role: String
    let gender: String
    let pics: Int
}

struct ParticipantsForJudge: Codable {
    let status: String
    let data: [Participant]
}

struct SportfestLocationCreate: Encodable {
    let location_id: String
    let CONTACTPERSON_ID: String
    let fest_name: String
    let fest_start: String
    let fest_end: String
}

struct SportFestSmall: Identifiable, Decodable {
    let ID: String
    let DETAILS_ID: String
    
    var id: String {return self.ID}
}

struct SportFestSmallLowercase: Identifiable, Decodable {
    let id: String
    let details_id: String
}

struct SportfestLocationCreateResponse: Decodable {
    let data: SportFestSmall
    let status: String
}

struct SportFestsResponse: Decodable {
    let data: [SportfestData]
    let status: String
    
}

struct ContestWithFlag: Codable, Hashable {
    let participates: Bool
    let contest_id: String
}

struct ParticipaticClasses: Decodable {
    let in_it: Bool
    let grade: String
}

struct SportfestResponse: Decodable {
    let contests_with_flags: [ContestWithFlag]
    let data: SportfestData
    let status: String
}
struct SportfestData: Identifiable, Hashable, Codable {
    let cp_birth_year: String
    let cp_email: String
    let cp_firstname: String
    let cp_grade: String
    let cp_id: String
    let cp_lastname: String
    let cp_phone: String
    let cp_role: String
    let details_end: String
    let details_id: String
    let details_start: String
    let details_name: String
    let location_city: String
    let location_id: String
    let location_name: String
    let location_street: String
    let location_street_number: String
    let location_zipcode: String
    let sportfest_id: String
    let cts_wf: [ContestWithFlag]
    
    var id: String { return self.sportfest_id }
}
struct ContestData: Codable, Identifiable {
    let C_TEMPLATE_ID: String
    let ct_city: String
    let ct_cp_birth_year: String
    let ct_cp_email: String
    let ct_cp_firstname: String
    let ct_cp_grade: String
    let ct_cp_id: String
    let ct_cp_lastname: String
    let ct_cp_phone: String
    let ct_details_end: String
    let ct_details_id: String
    let ct_details_name: String
    let ct_details_start: String
    let ct_id: String
    let ct_location_name: String
    let ct_street: String
    let ct_streetnumber: String
    let ct_zipcode: String
    let sf_city: String
    let sf_cp_birth_year: String
    let sf_cp_email: String
    let sf_cp_firstname: String
    let sf_cp_grade: String
    let sf_cp_id: String
    let sf_cp_lastname: String
    let sf_cp_phone: String
    let sf_details_end: String
    let sf_details_id: String
    let sf_details_start: String
    let sf_id: String
    let sf_location_name: String
    let sf_street: String
    let sf_streetnumber: String
    let sf_zipcode: String
    
    var id: String { return self.ct_id }
}

struct ContestResponse: Codable {
    let data: ContestData
    let status: String
}

struct ContestForJudge: Codable, Identifiable {
    let ct_id: String
    let ct_end: String
    let ct_location_name: String
    let ct_name: String
    let ct_start: String
    let sf_name: String
    
    var id: String { return self.ct_id; }
}

struct ContestForJudgeResponse: Codable {
    let data: [ContestForJudge]
    let status: String
}

struct SportfestCreateData: Decodable, Identifiable {
    let ID: String
    let DETAILS_ID: String
    
    var id: String { return self.ID }
}

struct LocationData: Encodable {
    let NAME: String
    let ZIPCODE: String
    let CITY: String
    let STREET: String
    let STREETNUMBER: String
}

struct LocationUpdate: Decodable {
    let result: Location
    let status: String
    
}

struct CTemplate: Identifiable, Decodable {
    let ID: String
    let NAME: String
    let DESCRIPTION: String?
    let GRADERANGE: String?
    let EVALUATION: String
    let UNIT: String
    
    var id: String { return self.ID }
    
}

struct CreateCTemplateResponse: Decodable {
    let data: CTemplate
    let message: String
    let status: String
}

struct CTemplatesResponse: Decodable {
    let data: [CTemplate]
    let results: Int
    let status: String
}

struct CreateCTemplate: Encodable {
    let NAME: String
    let DESCRIPTION: String?
    let GRADERANGE: String?
    let EVALUATION: String
    let UNIT: String
}
struct UpdateCTemplateResponse: Decodable {
    let result: CTemplate
    let status: String
}

struct AssignContestSportFestCreate: Encodable {
    let LOCATION_ID: String
    let CONTACTPERSON_ID: String
    let C_TEMPLATE_ID: String
    let NAME : String
    let START: String
    let END: String
    let HELPERS: [String]
}


    
var STORE : [String:[ResultInfo]] = [:];

var SessionToken: String?
var UserId: String?


struct IsLoggedIn: Decodable {
    let is_logged_in: Bool
    let role: String
}

func isUserLoggedIn() async -> IsLoggedIn {
    let url = URL(string: "\(apiURL)/loggedin")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        let result = try await executeURLRequestAsync(request: request)
        switch result {
        case .success(_, let data):
            if let decodedResponse = try? JSONDecoder().decode(IsLoggedIn.self, from: data) {
                return decodedResponse
            }
        default:
            break
        }
    } catch {
        print("Error during request: \(error)")
    }
    return IsLoggedIn(is_logged_in: false, role: "User")
}

import Foundation

enum MyResult<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
}

func fetch<T: Codable>(
    from urlString: String,
    ofType type: T.Type,
    cookies: [String: String]? = nil,
    method: String,
    completion: @escaping (MyResult<T, Error>) -> Void
) {
    guard let url = URL(string: urlString) else {
        completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: nil)))
        return
    }
    
    // Create a URLRequest
    var request = URLRequest(url: url)
    request.httpMethod = method;
    request.setValue("application/json", forHTTPHeaderField: "Content-Type");
    
    // Add cookies to the header if provided
    if let cookies = cookies {
        let cookieHeader = cookies.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
        request.addValue(cookieHeader, forHTTPHeaderField: "Cookie")
    }
    
    // Create a data task
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -1, userInfo: nil)))
            return
        }
        
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            completion(.success(decodedData))
        } catch {
            completion(.failure(error))
        }
    }
    
    // Start the task
    task.resume()
}





