use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct ParentChildren {
    pub PARENT_ID: String,
    pub CHILD_ID: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct UpdateChild {
    pub pics: Option<u8>,
    pub disabilities: Option<String>
}

