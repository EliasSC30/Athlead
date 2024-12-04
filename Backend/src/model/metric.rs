use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Metric {
    pub ID: String,
    pub TIME: Option<f64>,
    pub TIMEUNIT: Option<String>,
    pub LENGTH: Option<f64>,
    pub LENGTHUNIT: Option<String>,
    pub WEIGHT: Option<f64>,
    pub WEIGHTUNIT: Option<String>,
    pub AMOUNT: Option<f64>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow, Clone)]
#[allow(non_snake_case)]
pub struct CreateMetric {
    pub TIME: Option<f64>,
    pub TIMEUNIT: Option<String>,
    pub LENGTH: Option<f64>,
    pub LENGTHUNIT: Option<String>,
    pub WEIGHT: Option<f64>,
    pub WEIGHTUNIT: Option<String>,
    pub AMOUNT: Option<f64>,
}

#[derive(Debug, Deserialize, Serialize, sqlx::Type)]
#[sqlx(type_name = "ENUM")]
pub enum TimeUnit {
    SECONDS,
    MINUTES,
    HOURS,
}

#[derive(Debug, Deserialize, Serialize, sqlx::Type)]
#[sqlx(type_name = "ENUM")]
pub enum LengthUnit {
    CENTIMETERS,
    METERS,
    KILOMETERS,
}

#[derive(Debug, Deserialize, Serialize, sqlx::Type)]
#[sqlx(type_name = "ENUM")]
pub enum WeightUnit {
    GRAMS,
    KILOGRAMS,
    TONS,
}
