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
        print("Simulator")
        return "http://localhost:8000"
#else
        print("Device")
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
}

struct LoginData: Encodable {
    let email: String
    let password: String?
    let token: String?
}

struct LoginResponse: Decodable {
    let data: String
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


/*
 "cp_birth_year": "2003",
 "cp_email": "jan.wichmann23@icloud.com",
 "cp_firstname": "Jan",
 "cp_grade": "4",
 "cp_id": "d0c09d12-2fe5-41d7-ae5c-223bf7e7ef1c",
 "cp_lastname": "Wichmann ",
 "cp_phone": "+49 173 6609293",
 "cp_role": "ADMIN",
 "details_end": "2024-12-12T22:40:53",
 "details_id": "8998d965-5dff-4a65-ab6a-07240888eef1",
 "details_start": "2024-12-12T22:40:53",
 "location_city": "Wielsoch",
 "location_id": "01fa6e46-2871-4342-b117-8dc6e521e4f4",
 "location_name": "Die Messis",
 "location_street": "Meßplatzstraße",
 "location_street_number": "25",
 "location_zipcode": "69168",
 "sportfest_id": "52d644c8-782e-413c-a9e8-9a973f5e09b1"
 */

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
var STORE : [String:[ResultInfo]] = [:];

var SessionToken: String?



