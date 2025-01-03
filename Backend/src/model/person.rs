use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Person {
    pub ID: String,
    pub FIRSTNAME: String,
    pub LASTNAME: String,
    pub EMAIL: String,
    pub PHONE: String,
    pub GRADE: Option<String>,
    pub BIRTH_YEAR: Option<String>,
    pub ROLE: String,
    pub GENDER: String,
    pub PICS: u8,
    pub PASSWORD: String,
    pub DISABILITIES: String,
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct Participant {
    pub id: String,
    pub f_name: String,
    pub l_name: String,
    pub email: String,
    pub phone: String,
    pub grade: Option<String>,
    pub birth_year: Option<String>,
    pub role: String,
    pub gender: String,
    pub pics: u8,
    pub disabilities: String,
}

impl Person {
    pub(crate) fn clone(&self) -> Person {
        Person {
            ID: self.ID.clone(),
            FIRSTNAME: self.FIRSTNAME.clone(),
            LASTNAME: self.LASTNAME.clone(),
            EMAIL: self.EMAIL.clone(),
            PHONE: self.PHONE.clone(),
            GRADE: self.GRADE.clone(),
            BIRTH_YEAR: self.BIRTH_YEAR.clone(),
            ROLE: self.ROLE.clone(),
            GENDER: self.GENDER.clone(),
            PICS: self.PICS.clone(),
            PASSWORD: self.PASSWORD.clone(),
            DISABILITIES: self.DISABILITIES.clone()
        }
    }
}

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct PersonBatch {
    pub csv: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct CreatePerson {
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub phone: String,
    pub grade: Option<String>,
    pub birth_year: Option<String>,
    pub role: String,
    pub gender: String,
    pub pics: u8,
    pub password: String,
    pub disabilities: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UpdatePerson {
    pub ROLE: Option<String>
}
