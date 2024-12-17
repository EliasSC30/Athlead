use std::fmt;
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Person {
    pub ID: String,
    pub FIRSTNAME: String,
    pub LASTNAME: String,
    pub EMAIL: String,
    pub PHONE: String,
    pub GRADE: Option<String>,
    pub BIRTH_YEAR: Option<String>,
    pub ROLE: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct PersonBatch {
    pub csv: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct CreatePerson {
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub phone: String,
    pub grade: Option<String>,
    pub birth_year: Option<String>,
    pub role: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UpdatePerson {
    pub ROLE: Option<String>
}
