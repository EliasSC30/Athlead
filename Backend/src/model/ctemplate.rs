use serde::{Deserialize, Serialize};
use crate::model;

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CTemplate {
    pub ID: String,
    pub NAME: String,
    pub DESCRIPTION: Option<String>,
    pub GRADERANGE: Option<String>,
    pub EVALUATION: String,
    pub UNIT: String
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateCTemplate {
    pub NAME: String,
    pub DESCRIPTION: Option<String>,
    pub GRADERANGE: Option<String>,
    pub EVALUATION: String,
    pub UNIT: String
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct UpdateCTemplate {
    pub ID: Option<String>,
    pub NAME: Option<String>,
    pub DESCRIPTION: Option<String>,
    pub GRADERANGE: Option<String>,
    pub EVALUATION: Option<String>,
    pub UNIT: Option<String>
}

