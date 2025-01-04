use serde::{Deserialize, Serialize};

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
pub struct UpdateCTemplate {
    #[allow(non_snake_case)]
    pub ID: Option<String>,
    #[allow(non_snake_case)]
    pub NAME: Option<String>,
    #[allow(non_snake_case)]
    pub DESCRIPTION: Option<String>,
    #[allow(non_snake_case)]
    pub GRADERANGE: Option<String>,
    #[allow(non_snake_case)]
    pub EVALUATION: Option<String>,
    #[allow(non_snake_case)]
    pub UNIT: Option<String>
}

