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
    // Person Fields
    pub role: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Auth {
    pub pwd_encrypted: String,
    pub person_id: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Authentication {
    pub AUTH: String,
    pub PERSON_ID: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Login {
    pub email: String,
    pub password: Option<String>,
    pub token: Option<String>,
}
