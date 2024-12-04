use chrono::{NaiveDateTime};
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Contest {
    pub ID: String,
    pub SPORTFEST_ID: String,
    pub DETAILS_ID: String,
    pub CONTESTRESULT_ID: Option<String>,
    pub C_TEMPLATE_ID: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct ContestMaster {
    pub ct_id: String,
    pub sf_id: String,

    pub sf_details_id : String,
    pub sf_details_start : NaiveDateTime,
    pub sf_details_end : NaiveDateTime,

    pub ct_details_id : String,
    pub ct_details_name: Option<String>,
    pub ct_details_start : NaiveDateTime,
    pub ct_details_end : NaiveDateTime,

    pub sf_cp_id : String,
    pub sf_cp_firstname : String,
    pub sf_cp_lastname : String,
    pub sf_cp_email : String,
    pub sf_cp_phone : String,
    pub sf_cp_grade : Option<String>,
    pub sf_cp_birth_year : Option<String>,

    pub ct_cp_id : String,
    pub ct_cp_firstname : String,
    pub ct_cp_lastname : String,
    pub ct_cp_email : String,
    pub ct_cp_phone : String,
    pub ct_cp_grade : Option<String>,
    pub ct_cp_birth_year : Option<String>,

    pub sf_city: String,
    pub sf_zipcode: String,
    pub sf_street: String,
    pub sf_streetnumber: String,
    pub sf_location_name: Option<String>,

    pub ct_city: String,
    pub ct_zipcode: String,
    pub ct_street: String,
    pub ct_streetnumber: String,
    pub ct_location_name: Option<String>,

    pub CONTESTRESULT_ID: Option<String>,
    pub C_TEMPLATE_ID: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct GetContestWithResult {
    pub sf_id: String,

    pub cp_id : String,
    pub cp_firstname : String,
    pub cp_lastname : String,
    pub cp_email : String,
    pub cp_phone : String,
    pub cp_grade : Option<String>,
    pub cp_birth_year : Option<String>,

    pub city: String,
    pub zipcode: String,
    pub street: String,
    pub streetnumber: String,
    pub location_name: Option<String>,

    pub details_id : String,
    pub details_name: String,
    pub details_start : NaiveDateTime,
    pub details_end : NaiveDateTime,

    pub CONTESTRESULT_ID: Option<Vec<String>>,
    pub C_TEMPLATE_ID: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateContest {
    pub SPORTFEST_ID: String,
    pub DETAILS_ID: String,
    pub CONTESTRESULT_ID: Option<String>,
    pub C_TEMPLATE_ID: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct UpdateContest {
    pub SPORTFEST_ID: Option<String>,
    pub DETAILS_ID: Option<String>,
    pub CONTESTRESULT_ID: Option<String>,
    pub C_TEMPLATE_ID: Option<String>,
}
