//
//  DataStore.swift
//  Athlead
//
//  Created by Oezcan, Elias on 01.12.24.
//

import Foundation

var apiURL: String {
    get {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return "http://localhost:8000"
        }
        #if targetEnvironment(simulator)
                return "http://localhost:8000"
        #else
                return "http://45.81.234.175:8000"
        #endif
    }
}

var SessionToken: String?
var User: Person?
var UserToken: String?
var HasInternetConnection: Bool = true;

enum MyResult<Success, Failure> {
    case success(Success)
    case failure(Failure)
}


struct UploadPhoto: Codable {
    let name: String
    let data: String
}

struct UploadPhotoResponse: Codable {
    let status: String
}

struct Photo: Codable {
    let data: String
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

struct LoginResponse: Codable {
    let status: String
    let user: Person
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

struct PersonsResponse: Codable {
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
    let gender: String
    let email: String
    let phone: String
    let birth_year: String?
    let grade: String?
    let role: String
    let pics: Int
    let disabilities: String
    let password: String
}

struct PersonCreateResponse: Codable {
    let data: Person
    let status: String
}

struct Person: Identifiable, Hashable, Codable {
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
    let DISABILITIES: String
    
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

struct SportFestsResponse: Codable {
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
    let cp_birth_year: String?
    let cp_email: String
    let cp_firstname: String
    let cp_grade: String?
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
struct ContestData: Codable, Identifiable, Hashable {
    let C_TEMPLATE_ID: String
    let ct_city: String
    let ct_cp_birth_year: String?
    let ct_cp_email: String
    let ct_cp_firstname: String
    let ct_cp_grade: String?
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
    let sf_cp_birth_year: String?
    let sf_cp_email: String
    let sf_cp_firstname: String
    let sf_cp_grade: String?
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
    let ct_unit: String
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

struct ContestResult: Codable, Identifiable {
    let ct_id: String

    let p_id: String
    let p_role: String
    let p_firstname: String
    let p_lastname: String
    let p_email: String
    let p_phone: String
    let p_grade: String?
    let p_birth_year: String?

    var value: Float64?
    var unit: String?
    
    var id: String { return UUID().uuidString }
}

struct ContestResultsResponse: Codable {
    let status: String
    let ascending: String
    let data: [ContestResult]
}

struct PersonToResult: Codable {
    let m_id: String
    let p_id: String
    let value: Float64
}
struct PatchContestResultsResponse: Codable {
    let status: String
    let updated_fields: Int
}

struct PatchContestResult: Codable {
    let p_id: String
    let value: Float64
}
struct PatchContestResults: Codable {
    var results: [PatchContestResult]
}

struct IsParticipantCheckResponse: Codable {
    let status: String
    let is_participant: Bool
}

struct ParentsChildrenResponse: Codable {
    let status: String
    let data: [Person]
}

struct IsLoggedInResponse: Codable {
    let is_logged_in: Bool
    let person: Person
}

struct PersonWithPoint: Codable {
    let p_f_name: String
    let p_l_name: String
    let p_email: String
    let p_phone: String
    let p_grade: String?
    let p_birth_year: String?
    let p_role: String
    let p_gender: String
    let p_pics: Int
    let points: Int
}
struct PersonWithResult: Identifiable, Codable {
    let p_f_name: String
    let p_l_name: String
    let p_email: String
    let p_phone: String
    let p_grade: String?
    let p_birth_year: String?
    let p_role: String
    let p_gender: String
    let p_pics: Int
    let value: Float64
    let unit: String
    let points: Int
    
    var id: String { return self.p_email }
}
struct ContestWithResults: Codable {
    let id: String
    let contest_name: String
    let unit: String
    let results: [PersonWithResult]
}

struct SportfestResultMasterResponse: Codable {
    let status: String
    let contests: [ContestWithResults]
    let contestants_totals: [PersonWithPoint]
}

struct PersonToContest: Codable {
    let participant_ids: [String]
}

struct PersonToContestResponse: Codable {
    let status: String
    let added_persons: Int
}

struct UpdateContestantResultInner: Codable {
    let p_id: String
    let value: Float64
}
    
struct UpdateContestantResultOuter: Codable {
    let results: [UpdateContestantResultInner]
}
struct UpdateContestantResultResponse: Codable {
    let status: String
    let updated_fields: Int
}

struct ChildUpdate: Codable {
    let disabilities: String?
    let pics: Int?
}

struct ChildUpdateResponse: Codable {
    let status: String
}

enum MsgType: String, Codable {
    case crUpdate = "CR_UPDATE"
    case connect = "CONNECT"
}

struct CRUpdateData: Codable {
    let contestant_id: String
    let value: Double
}

struct Message: Codable {
    let msg_type: MsgType
    let data: DataWrapper
}

enum DataWrapper: Codable {
    case crUpdate(CRUpdateData)
    case connect(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let crUpdateData = try? container.decode(CRUpdateData.self) {
            self = .crUpdate(crUpdateData)
        } else if let connectData = try? container.decode(String.self) {
            self = .connect(connectData)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Data is not of expected type.")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .crUpdate(let data):
            try container.encode(data)
        case .connect(let data):
            try container.encode(data)
        }
    }
}

struct SportFestResults : Codable {
    let status: String
    let contestants_totals: [PersonWithPoint]
    let contests: [ContestWithResults]
}

struct CSVPersonBatch: Codable {
    let csv: String
}

struct CSVPersonBatchResponse: Codable {
    let status: String
    let updated_fields: Int
}

struct HelperResponse: Codable {
    let status: String
    let helper: [Helper]
}
struct Helper: Codable {
    let birth_year: String?
    let description: String?
    let disabilities: String?
    let email: String
    let first_name: String
    let gender: String
    let grade: String?
    let id: String
    let last_name: String
    let phone: String
    let pics: Int
    let role: String
}

extension String {
    func truncateUntilSemicolon() -> String {
        if let semicolonIndex = self.firstIndex(of: ";") {
            return String(self[..<semicolonIndex])
        }
        return self
    }
}


extension String {
    func truncated(to length: Int) -> String {
        if self.count > length {
            let endIndex = self.index(self.startIndex, offsetBy: length)
            return self[self.startIndex..<endIndex] + "..."
        } else {
            return self
        }
    }
}


