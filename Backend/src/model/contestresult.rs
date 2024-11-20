use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct ContestResult {
    pub ID: String,
    pub PERSON_ID: String,
    pub CONTESTRESULT_ID: String,
    pub METRIC_ID: String,
}
