use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct ContestResult {
    pub ID: String,
    pub PERSON_ID: String,
    pub CONTEST_ID: String,
    pub METRIC_ID: Option<String>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateContestResult {
    pub PERSON_ID: String,
    pub CONTEST_ID: String,

    // Metric Fields
    pub value: f64,
    pub unit: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct UpdateContestResult {
    pub value: f64,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateContestResultContestView {
    pub p_id: String,

    // Metric Fields
    pub value: f64,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct BatchContestResults {
    pub results: Vec<CreateContestResultContestView>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct PatchContestResults {
    pub results: Vec<CreateContestResultContestView>,
}
#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct ContestResultContestView {
    pub ct_id: String,

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
    pub value: Option<f64>,
    pub unit: Option<String>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateContestResults {
    pub CONTEST_ID: String,
    pub PERSON_ID: Vec<String>,
    pub METRIC_ID: Vec<String>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct WsMsg {
    pub msg_type: String,
    pub data: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct WsCRMsg {
    pub contest_id: String,
    pub contestant_id: String,
    pub value: String,
}

