use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Pupil {
    pub id: String,
    pub firstname: String,
    pub lastname: String,
    pub email: String,
    pub password: String,
    pub created_at: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct CreatePupil {
    pub firstname: String,
    pub lastname: String,
    pub email: String,
    pub password: String,
}