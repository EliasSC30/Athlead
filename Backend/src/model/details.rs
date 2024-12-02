use chrono::{DateTime, NaiveDateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Details {
    pub ID: String,
    pub LOCATION_ID: String,
    pub CONTACTPERSON_ID: String,
    pub NAME: Option<String>,
    pub START: NaiveDateTime,
    pub END: NaiveDateTime,
}


#[derive(Serialize, Deserialize, Debug)]
pub struct CreateDetails {
    pub LOCATION_ID: String,
    pub CONTACTPERSON_ID: String,
    pub NAME: Option<String>,
    pub START: NaiveDateTime,
    pub END: NaiveDateTime
}

impl CreateDetails {
    pub fn from(
                loc_id : String,
                contact_id : String,
                name : Option<String>,
                start : NaiveDateTime,
                end : NaiveDateTime)
     -> Self
    {
        CreateDetails {
            LOCATION_ID : loc_id,
            CONTACTPERSON_ID : contact_id,
            NAME : name,
            START : start,
            END : end}
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct UpdateDetails {
    pub LOCATION_ID: Option<String>,
    pub CONTACTPERSON_ID: Option<String>,
    pub NAME: Option<String>,
    pub START: Option<NaiveDateTime>,
    pub END: Option<NaiveDateTime>
}