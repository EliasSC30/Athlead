use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Helper {
    pub contest_id: String,
    pub helper_id: String,
    pub description: String,
}

