use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Sportfest {
    pub ID: String,
    pub DETAILS_ID: String,
}

#[derive(Debug, Deserialize, Serialize)]
#[allow(non_snake_case)]
pub struct SFMasterStacked {
    pub sf: SportfestMaster,
}

#[derive(Debug, Deserialize, Serialize)]
#[allow(non_snake_case)]
pub struct UpdateSportfest {
    // Detail Fields
    pub contact_person_id: Option<String>,
    pub fest_name: Option<String>,
    pub fest_start: Option<NaiveDateTime>,
    pub fest_end: Option<NaiveDateTime>,

    // Location Fields
    pub location_id: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct CreateSportfest {
    // Detail Fields
    pub CONTACTPERSON_ID: String,
    pub fest_name: String,
    pub fest_start: NaiveDateTime,
    pub fest_end: NaiveDateTime,

    // Location Fields
    pub city: String,
    pub zip_code: String,
    pub street: String,
    pub streetnumber: String,
    pub location_name: String
}

#[derive(Serialize, Deserialize, Debug)]
pub struct CreateSportfestWithLocation {
    // Detail Fields
    pub CONTACTPERSON_ID: String,
    pub fest_name: String,
    pub fest_start: NaiveDateTime,
    pub fest_end: NaiveDateTime,

    // Location Fields
    pub location_id: String
}

#[derive(Serialize, Deserialize, Debug)]
pub struct PartClassesWithInItFlag {
    pub in_it: bool,
    pub grade: String,
}
#[derive(Serialize, Deserialize, Debug)]
pub struct ContestWithPartFlag {
    pub participates: bool,
    pub contest_id: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateContestForFest {
    pub C_TEMPLATE_ID: String,
    pub HELPERS: Vec<String>,
    //Details fields
    pub LOCATION_ID: String,
    pub CONTACTPERSON_ID: String,
    pub NAME: String,
    pub START: NaiveDateTime,
    pub END: NaiveDateTime,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow, Clone)]
#[allow(non_snake_case)]
pub struct PersonWithPoint{
    pub p_f_name: String,
    pub p_l_name: String,
    pub p_email: String,
    pub p_phone: String,
    pub p_grade: Option<String>,
    pub p_birth_year: Option<String>,
    pub p_role: String,
    pub p_gender: String,
    pub p_pics: u8,
    pub points: u32
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow, Clone)]
#[allow(non_snake_case)]
pub struct ContestWithResults{
    pub id: String,
    pub unit: String,
    pub results: Vec<PersonWithPoint>
}


#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct SportfestMaster {
    pub sportfest_id : String,

    pub details_id : String,
    pub details_name: String,
    pub details_start : NaiveDateTime,
    pub details_end : NaiveDateTime,

    pub location_id : String,
    pub location_name : String,
    pub location_city : String,
    pub location_zipcode : String,
    pub location_street : String,
    pub location_street_number : String,

    pub cp_id : String,
    pub cp_role : String,
    pub cp_firstname : String,
    pub cp_lastname : String,
    pub cp_email : String,
    pub cp_phone : String,
    pub cp_grade : Option<String>,
    pub cp_birth_year : Option<String>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct SportfestMasterWithArrays {
    pub sportfest_id : String,

    pub details_id : String,
    pub details_name: String,
    pub details_start : NaiveDateTime,
    pub details_end : NaiveDateTime,

    pub location_id : String,
    pub location_name : String,
    pub location_city : String,
    pub location_zipcode : String,
    pub location_street : String,
    pub location_street_number : String,

    pub cp_id : String,
    pub cp_role : String,
    pub cp_firstname : String,
    pub cp_lastname : String,
    pub cp_email : String,
    pub cp_phone : String,
    pub cp_grade : Option<String>,
    pub cp_birth_year : Option<String>,

    pub part_cls_wf: Vec<PartClassesWithInItFlag>,
    pub cts_wf: Vec<ContestWithPartFlag>
}
