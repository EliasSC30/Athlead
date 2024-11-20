use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Class {
    pub id: String,
    pub teacher_id: String,
    pub grade: String,
    pub section: String,
    pub created_at: String,
}