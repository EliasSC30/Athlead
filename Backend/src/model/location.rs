use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Location {
    pub ID: String,
    pub CITY: String,
    pub ZIPCODE: String,
    pub STREET: String,
    pub STREETNUMBER: String,
    pub NAME: Option<String>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct CreateLocation {
    pub CITY: String,
    pub ZIPCODE: String,
    pub STREET: String,
    pub STREETNUMBER: String,
    pub NAME: Option<String>,
}