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
    let status: String
}



struct ResultInfo {
    let name: String
    let metric: Metric
}

struct SportFestDisplay: Identifiable, Hashable {
    let ID: String
    let DETAILS_ID: String
    let CONTACTPERSON_ID: String
    let NAME: String
    let LOCATION_ID: String
    let START: Date
    let END: Date
    
    var id: String { return self.ID }
}

struct SportFestsResponse: Decodable {
    let data: [SportFest]
    let results: Int
    let status: String
}

struct SportFest: Identifiable, Decodable {
    let id: String
    let details_id: String
}

struct DetailsResponse: Decodable {
    let data: [Detail]
    let results: Int
    let status: String
}

struct DetailResponse: Decodable {
    let data: Detail
    let status: String
}
struct Detail: Identifiable, Decodable, Hashable {
    let ID: String
    let CONTACTPERSON_ID: String
    let NAME: String
    let LOCATION_ID: String
    let START: String
    let END: String
    
    var id: String { return self.ID }
}

struct SportfestDetailsResponse: Decodable {
    let result: SportfestDetails
    let status: String
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
    
    var id: String { return self.ID }
}

struct SportfestDetails: Identifiable, Decodable {
    let ID: String
    let NAME: String
    let LOCATION_ID: String
    let CONTACTPERSON_ID: String
    let START: String
    let END: String
    
    var id: String { return self.ID }
}

struct SportfestDetailsCreate: Encodable {
    let NAME: String
    let LOCATION_ID: String
    let CONTACTPERSON_ID: String
    let START: String
    let END: String
}

struct SportfestLocationCreate: Encodable {
    let CONTACTPERSON_ID: String
    let fest_name: String
    let fest_start: String
    let fest_end: String
    let city: String
    let zip_code: String
    let street: String
    let streetnumber: String
    let location_name: String
}

struct SportFestResponse: Decodable {
    let data: SportFest
    let message: String
    let status: String
}
struct SportfestCreateResponse: Decodable {
    let data: SportfestCreateData
    let status: String
    
}

struct SportFestSingleResponse: Decodable {
    let data: SportfestData
    let status: String
    
}

struct SportfestData: Identifiable, Hashable, Decodable {
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
    let location_city: String
    let location_id: String
    let location_name: String
    let location_street: String
    let location_street_number: String
    let location_zipcode: String
    let sportfest_id: String
    
    var id: String { return self.sportfest_id }
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
    let START: Date
    let END: Date
}

struct IsLoggedIn: Decodable {
    let is_logged_in: Bool
    let role: String
}
    
var STORE : [String:[ResultInfo]] = [:];

var SessionToken: String?
var UserId: String?




func isUserLoggedIn() async -> IsLoggedIn? {
    let url = URL(string: "\(apiURL)/loggedin")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    
    //print cookies which are send with the request
    let cookies = HTTPCookieStorage.shared.cookies(for: url)
    cookies?.forEach { cookie in
        print("Cookie: \(cookie.name)=\(cookie.value)")
    }
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("Invalid response status code")
            return nil
        }
        
        let loginResponse = try JSONDecoder().decode(IsLoggedIn.self, from: data)
        return loginResponse
    } catch {
        print("Error trying to login: \(error)")
        return nil
    }
}




