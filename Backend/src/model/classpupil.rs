use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct ClassPupil {
    pub id: i32,
    pub class_id: i32,
    pub pupil_id: i32,
}