use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Metric {
    pub id: String,
    pub value: f64,
    pub unit: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow, Clone)]
#[allow(non_snake_case)]
pub struct CreateMetric {
    pub value: f64,
    pub unit: String,
}
