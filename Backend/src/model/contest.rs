use chrono::{NaiveDateTime};
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Contest {
    pub ID: String,
    pub SPORTFEST_ID: String,
    pub DETAILS_ID: String,
    pub C_TEMPLATE_ID: String,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct ContestForJudge {
    pub ct_id: String,
    pub ct_name: String,
    pub ct_start: NaiveDateTime,
    pub ct_end: NaiveDateTime,
    pub ct_location_name: String,
    pub ct_unit: String,
    pub sf_name: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow, Clone)]
#[allow(non_snake_case)]
pub struct ContestEvaluation {
    pub ct_id: String,
    pub ct_details_id: String,
    pub evaluation: String,
    pub unit: String,
    pub p_f_name: String,
    pub p_l_name: String,
    pub p_email: String,
    pub p_phone: String,
    pub p_grade: Option<String>,
    pub p_birth_year: Option<String>,
    pub p_role: String,
    pub p_gender: String,
    pub p_pics: u8,

    pub length: Option<f64>,
    pub length_unit: Option<String>,
    pub weight: Option<f64>,
    pub weight_unit: Option<String>,
    pub time: Option<f64>,
    pub time_unit: Option<String>,
    pub amount: Option<f64>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct UnitWrapper {
    pub unit: String
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
    pub NAME: String,
    pub ct_name: String,
    pub ct_description: Option<String>,
    pub ct_graderange: Option<String>,
    pub ct_evaluation: String,
    pub ct_unit: String
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateParticipantsForContest {
    pub participant_ids: Option<Vec<String>>,
    pub classes: Option<Vec<String>>
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct UpdateContest {
    pub SPORTFEST_ID: Option<String>,
    pub DETAILS_ID: Option<String>,
    pub C_TEMPLATE_ID: Option<String>,
}
