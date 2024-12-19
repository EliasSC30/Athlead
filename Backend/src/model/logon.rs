use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Register {
    pub password: String,

    // Fields to create the person
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub phone: String,
    pub grade: Option<String>,
    pub birth_year: Option<String>,
    pub role: String,
    pub gender: String,
    pub pics: u8,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Auth {
    pub person_id: String,
    pub pwd_encrypted: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Authentication {
    pub PERSON_ID: String,
    pub PASSWORD: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Login {
    pub email: String,
    pub password: Option<String>,
}
