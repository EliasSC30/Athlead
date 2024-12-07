use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct ContestResult {
    pub ID: String,
    pub PERSON_ID: String,
    pub CONTEST_ID: String,
    pub METRIC_ID: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateContestResult {
    pub PERSON_ID: String,
    pub CONTEST_ID: String,

    // Metric Fields
    pub time: Option<f64>,
    pub time_unit: Option<String>,
    pub length: Option<f64>,
    pub length_unit: Option<String>,
    pub weight: Option<f64>,
    pub weight_unit: Option<String>,
    pub amount: Option<f64>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateContestResultContestView {
    pub p_id: String,

    // Metric Fields
    pub time: Option<f64>,
    pub time_unit: Option<String>,
    pub length: Option<f64>,
    pub length_unit: Option<String>,
    pub weight: Option<f64>,
    pub weight_unit: Option<String>,
    pub amount: Option<f64>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct ContestResultContestView {
    pub CONTEST_ID: String,

    // Person Fields
    pub p_id: String,
    pub p_role: String,
    pub p_firstname: String,
    pub p_lastname: String,
    pub p_email: String,
    pub p_phone: String,
    pub p_grade: Option<String>,
    pub p_birth_year: Option<String>,

    // Metric Fields
    pub time: Option<f64>,
    pub time_unit: Option<String>,
    pub length: Option<f64>,
    pub length_unit: Option<String>,
    pub weight: Option<f64>,
    pub weight_unit: Option<String>,
    pub amount: Option<f64>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateContestResults {
    pub CONTEST_ID: String,
    pub PERSON_ID: Vec<String>,
    pub METRIC_ID: Vec<String>,
}
