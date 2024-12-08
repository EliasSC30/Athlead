use std::fmt;
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Person {
    pub ID: String,
    pub CONTACTINFO_ID: String,
    pub ROLE: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct CreatePerson {
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub phone: String,
    pub grade: Option<String>,
    pub birth_year: Option<String>,
    // Person Fields
    pub role: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UpdatePerson {
    pub CONTACTINFO_ID: Option<String>,
    pub ROLE: Option<String>
}
