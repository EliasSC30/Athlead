use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Teacher {
    pub id: i32,
    pub firstname: String,
    pub lastname: String,
    pub email: String,
    pub password: String,
    pub created_at: String
}