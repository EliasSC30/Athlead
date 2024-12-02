use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct ContactInfo {
    pub ID: String,
    pub FIRSTNAME: String,
    pub LASTNAME: String,
    pub EMAIL: String,
    pub PHONE: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct CreateContactInfo {
    pub FIRSTNAME: String,
    pub LASTNAME: String,
    pub EMAIL: String,
    pub PHONE: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct UpdateContactInfo {
    pub FIRSTNAME: Option<String>,
    pub LASTNAME: Option<String>,
    pub EMAIL: Option<String>,
    pub PHONE: Option<String>,
}
