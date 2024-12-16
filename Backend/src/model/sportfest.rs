use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Sportfest {
    pub ID: String,
    pub DETAILS_ID: String,
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
pub struct UpdateSportfest {
    pub DETAILS_ID: Option<String>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateContestForFest {
    pub C_TEMPLATE_ID: String,
    //Details fields
    pub LOCATION_ID: String,
    pub CONTACTPERSON_ID: String,
    pub NAME: String,
    pub START: NaiveDateTime,
    pub END: NaiveDateTime,
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
