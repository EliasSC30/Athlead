use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Sportfest {
    pub ID: String,
    pub DETAILS_ID: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct CreateSportfest {
    pub DETAILS_ID: String,
}