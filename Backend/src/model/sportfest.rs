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
    pub DETAILS_ID: String,
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
    pub NAME: Option<String>,
    pub START: NaiveDateTime,
    pub END: NaiveDateTime,
    // End of details fields
    pub CONTESTRESULT_ID: Option<String>,
}
