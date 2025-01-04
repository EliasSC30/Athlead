use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct ParentChildren {
    pub PARENT_ID: String,
    pub CHILD_ID: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct UpdateChild {
    pub pics: Option<u8>,
    pub disabilities: Option<String>
}

