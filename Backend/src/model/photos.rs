use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct PhotoUpload {
    pub name: String,
    pub data: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct Photoname {
    pub name: String,
}