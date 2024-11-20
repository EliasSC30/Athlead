use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Details {
    pub ID: String,
    pub LOCATION_ID: String,
    pub CONTACTPERSON_ID: String,
    pub NAME: Option<String>,
    pub START: chrono::NaiveDateTime,
    pub END: chrono::NaiveDateTime,
}


#[derive(Serialize, Deserialize, Debug)]
pub struct CreateDetails {
    pub LOCATION_ID: String,
    pub CONTACTPERSON_ID: String,
    pub NAME: Option<String>,
    pub START: DateTime<Utc>,
    pub END: DateTime<Utc>
}