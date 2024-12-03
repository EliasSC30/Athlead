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
    pub METRIC_ID: String,
    // Metric Fields
    pub TIME: f64,
    pub TIMEUNIT: Option<String>,
    pub LENGTH: f64,
    pub LENGTHUNIT: Option<String>,
    pub WEIGHT: f64,
    pub WEIGHTUNIT: Option<String>,
    pub AMOUNT: f64,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateContestResults {
    pub CONTEST_ID: String,
    pub PERSON_ID: Vec<String>,
    pub METRIC_ID: Vec<String>,
}
