use chrono::{NaiveDateTime};
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Contest {
    pub ID: String,
    pub SPORTFEST_ID: String,
    pub DETAILS_ID: String,
    pub CONTESTRESULT_ID: String,
    pub C_TEMPLATE_ID: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct CreateContest {
    pub SPORTFEST_ID: String,
    pub DETAILS_ID: String,
    pub CONTESTRESULT_ID: Option<String>,
    pub C_TEMPLATE_ID: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct UpdateContest {
    pub SPORTFEST_ID: Option<String>,
    pub DETAILS_ID: Option<String>,
    pub CONTESTRESULT_ID: Option<String>,
    pub C_TEMPLATE_ID: Option<String>,
}
