use std::ops::Add;
use std::time::{SystemTime, UNIX_EPOCH};
use actix_web::{cookie, post, web, Error, HttpResponse, Responder};
use actix_web::cookie::{Cookie, Expiration};
use actix_web::cookie::Expiration::DateTime;
use actix_web::cookie::time::PrimitiveDateTime;
use serde_json::json;
use sqlx::MySqlPool;
use crate::api::encryption::encryption;
use crate::api::encryption::encryption::{crypt_str, crypt, generate_key, hash};
use crate::api::person::create_person;
use crate::model::logon::{Login, Register, Authentication};
use crate::model::person::{CreatePerson, Person};

const DEV: bool = true;
const TIME_OFFSET: u64 = 1734269586u64;
const TIMESTAMP_LENGTH: usize = 8;
const ID_LENGTH: usize = 36;
const DECRYPT_TOKEN_LENGTH: usize = ID_LENGTH+TIMESTAMP_LENGTH;
const ENCRYPT_TOKEN_PREFIX_LENGTH: usize = 6;
const ENCRYPT_TOKEN_LENGTH: usize = 136;
const ENCRYPT_TOKEN_LENGTH_WITH_PREFIX: usize = ENCRYPT_TOKEN_PREFIX_LENGTH + ENCRYPT_TOKEN_LENGTH;

fn our_time_now() -> u32 { (SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() - TIME_OFFSET) as u32 }

#[post("/register")]
pub async fn register_handler(body: web::Json<Register>, db: web::Data<MySqlPool>) -> impl Responder
{
    let password = body.password.clone();

    let pw_as_u32 = password.chars().into_iter().map(|c| c as u32).collect::<Vec<u32>>();

    let hashed_password = hash(&pw_as_u32);

    let email_query = sqlx::query("SELECT * FROM PERSON WHERE EMAIL = ?")
        .bind(&body.email)
        .fetch_optional(db.as_ref())
        .await;

    if email_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Select contact info error",
        "message": email_query.unwrap_err().to_string()
    })); };

    if email_query.unwrap().is_some() { return HttpResponse::InternalServerError().json(json!({
        "status": "Email already in use",
        "message": "Email already exists"
    })); };

    let person_for_create = CreatePerson {
        first_name: body.first_name.clone(),
        last_name: body.last_name.clone(),
        email: body.email.clone(),
        role: body.role.clone(),
        phone: body.phone.clone(),
        grade: body.grade.clone(),
        birth_year: body.birth_year.clone(),
        gender: body.gender.clone(),
        pics: body.pics,
        password: hashed_password.to_string()
    };

    let create_person = create_person(person_for_create, &db).await;
    if create_person.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Create person error",
    }))}

    let keys = generate_key();
    let mut to_crypt = create_person.as_ref().unwrap().ID.clone();
    to_crypt.push_str(encryption::u32_to_parsable_chars(our_time_now()).as_str());
    let new_token = crypt_str(&to_crypt, &keys.1, &keys.2);
    let mut new_token = encryption::BigInt::non_a7_u32_vec_to_exp_string(&new_token.parts);
    HttpResponse::Ok().json(json!({
            "status": "success",
            "data": new_token,
            "id": create_person.unwrap().ID
        }))
}

pub async fn check_token(mut token: String, db: &web::Data<MySqlPool>) -> Result<(String, Person),String> {
    if token.chars().count() != ENCRYPT_TOKEN_LENGTH_WITH_PREFIX { return Err(String::from("Token is too short")); };
    token = token[ENCRYPT_TOKEN_PREFIX_LENGTH..].to_string();

    if token.chars().any(|c| (c as u32) >(97+15) || (c as u32) < 97) { return Err(String::from("Invalid Token")); };
    let token_to_decrypt = encryption::BigInt { parts: encryption::BigInt::exp_str_to_u32_vec(&token) };
    let keys = generate_key();
    let decrypted_token = crypt(&token_to_decrypt,&keys.0,&keys.2);
    let decrypted_token = encryption::BigInt::a7_u32_vec_to_string(&decrypted_token.parts);
    if decrypted_token.len() != DECRYPT_TOKEN_LENGTH { return Err(String::from("Invalid token length")); };


    let (person_id,token_create_time) = decrypted_token.split_at(decrypted_token.len()-8);

    let last_login = encryption::chars_to_u32(&token_create_time.to_string());
    let now = our_time_now();
    if now < last_login { return Err(String::from("Invalid token create time")); };
    let seconds_since_last_login = now-last_login;

    let refresh_time_in_minutes = if DEV {9999999} else {15};
    if seconds_since_last_login / 60 > refresh_time_in_minutes {
        return Err("Token timed out".to_string());
    }

    let auth_query =
        sqlx::query_as!(Person, "SELECT * FROM PERSON WHERE ID = ?", person_id.to_string())
            .fetch_one(db.get_ref())
            .await;

    if auth_query.is_err() { return Err("No person with the id of the token\n".to_string() + &auth_query.unwrap_err().to_string()); };

    let now = our_time_now();
    let mut new_token = person_id.to_string();
    new_token.push_str(encryption::u32_to_parsable_chars(now).as_str());
    let encrypted = encryption::BigInt::non_a7_u32_vec_to_exp_string(&crypt_str(&new_token, &keys.1, &keys.2).parts);
    Ok((encrypted, auth_query.unwrap()))
}

pub async fn login_with_token(token: Option<String>, data: &web::Data<MySqlPool>) -> Result<(String, String, String), String>
{
    if token.is_none() { return Err(String::from("No valid login data was send")); };

    let token = token.unwrap();
    check_token(token, data).await.map(|t_and_p| (t_and_p.0,t_and_p.1.ID, t_and_p.1.ROLE))
}

#[post("/login")]
pub async fn login_handler(body: web::Json<Login>, db: web::Data<MySqlPool>) -> impl Responder
{
    let password = body.password.as_ref().clone().unwrap();

    let email_query = sqlx::query_as!(Person, "SELECT * FROM PERSON WHERE EMAIL = ?",
        &body.email)
        .fetch_one(db.as_ref())
        .await;
    if email_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Email not found",
    }));};
    let user = email_query.unwrap();

    let pw_as_u32 = password.chars().into_iter().map(|c| c as u32).collect::<Vec<u32>>();

    let hashed_password = hash(&pw_as_u32).to_string();

    if hashed_password != user.PASSWORD {return HttpResponse::InternalServerError().json(json!({
        "status": "Wrong password",
    }));};

    let keys = generate_key();
    let mut to_crypt = user.ID.clone();
    let now = our_time_now();
    to_crypt.push_str(encryption::u32_to_parsable_chars(now).as_str());
    let new_token = crypt_str(&to_crypt,&keys.1,&keys.2);
    let new_token = encryption::BigInt::non_a7_u32_vec_to_exp_string(&new_token.parts);
    let duration = cookie::time::Duration::days(9999);
    let expire_date = cookie::time::OffsetDateTime::now_utc().add(duration);
    let cookie = Cookie::build("Token", new_token.clone())
        .path("/")
        .expires(expire_date)
        .same_site(cookie::SameSite::Lax)
        .http_only(true)
        .finish();

    let mut res = HttpResponse::Ok().json(json!({"status": "success",}));

    res.add_cookie(&cookie);
    res

}
