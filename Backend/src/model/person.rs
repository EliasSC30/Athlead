use std::fmt;
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Person {
    pub ID: String,
    pub CONTACTINFO_ID: String,
    pub ROLE: Role,
}

#[derive(Debug, Deserialize, Serialize, sqlx::Type)]
#[sqlx(type_name = "ENUM")]
#[allow(non_snake_case)]
pub enum Role {
    ADMIN,
    JUDGE,
    CONTESTANT
}
impl std::convert::From<String> for Role {
    fn from(value: String) -> Self {
        match value.as_str() {
            "ADMIN" => Role::ADMIN,
            "JUDGE" => Role::JUDGE,
            "CONTESTANT" => Role::CONTESTANT,
            _ => Role::CONTESTANT
        }
    }
}

impl fmt::Display for Role {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Role::ADMIN => write!(f, "ADMIN"),
            Role::JUDGE => write!(f, "JUDGE"),
            Role::CONTESTANT => write!(f, "CONTESTANT"),
        }
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct CreatePerson {
    pub CONTACTINFO_ID: String,
    pub ROLE: Role
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UpdatePerson {
    pub CONTACTINFO_ID: Option<String>,
    pub ROLE: Option<Role>
}
