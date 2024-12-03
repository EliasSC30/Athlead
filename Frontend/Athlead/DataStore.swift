//
//  DataStore.swift
//  Athlead
//
//  Created by Oezcan, Elias on 01.12.24.
//

import Foundation

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
    let data: SportfestDetails
    let message: String
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
    let results: Int
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
    let CONTACTINFO_ID: String
    let ROLE: String
}

struct Person: Identifiable, Hashable, Decodable {
    let ID : String
    let CONTACTINFO_ID : String
    let ROLE: String
    
    var id: String { return self.ID }
}


struct PersonDisplay: Identifiable, Hashable, Decodable {
    let ID : String
    let PERSON: Person
    let CONTACTINFO_ID : String
    let CONTACT: Contact
    
    var id: String { return self.ID }
}

struct Contact: Identifiable, Hashable,Decodable {
    let ID: String
    let FIRSTNAME: String
    let LASTNAME: String
    let EMAIL: String
    let PHONE: String
    let BIRTH_YEAR: String?
    let GRADE: String?
    
    var id: String { return self.ID }
}
struct ContactInfoResponse: Decodable {
    let data: Contact
    let status: String
}

struct ContactInfoCreate: Encodable {
    let FIRSTNAME: String
    let LASTNAME: String
    let EMAIL: String
    let PHONE: String
    let BIRTH_YEAR: String?
    let GRADE: String?
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

struct SportFestResponse: Decodable {
    let data: SportFest
    let message: String
    let status: String
}
struct SportFestCreate: Encodable {
    let DETAILS_ID: String
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

var STORE : [String:[ResultInfo]] = [:];
