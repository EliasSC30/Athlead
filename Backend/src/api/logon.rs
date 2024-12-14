use num_bigint::BigInt;
use std::time::{SystemTime, UNIX_EPOCH};
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use crate::api::encryption::encryption;
use crate::api::encryption::encryption::{crypt_str, crypt, generate_key, hash};
use crate::api::person::create_person;
use crate::AppState;
use crate::model::logon::{Person_ID_Wrapper, Login, Register, Authentication};
use crate::model::person::{CreatePerson, Person};

#[post("/register")]
pub async fn register_handler(body: web::Json<Register>, data: web::Data<AppState>) -> impl Responder
{
    let password = body.password.clone();

    let pw_as_u32 = password.chars().into_iter().map(|c| c as u32).collect::<Vec<u32>>();

    let hashed_password = hash(&pw_as_u32);

    let email_query = sqlx::query("SELECT * FROM PERSON WHERE EMAIL = ?")
        .bind(&body.email)
        .fetch_optional(&data.db)
        .await;

    if email_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Select contactinfo error",
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
    };

    let create_person = create_person(person_for_create, &data).await;
    if create_person.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Create person error",
        "message": create_person.unwrap_err().to_string()
    }))}

    let auth_query = sqlx::query("INSERT INTO AUTHENTICATION (PERSON_ID, AUTH, LAST_LOGIN) VALUES (?, ?, ?)")
        .bind(&create_person.as_ref().clone().unwrap().ID)
        .bind(&hashed_password)
        .bind(SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs().to_string())
        .execute(&data.db)
        .await;

    let keys = generate_key();
    let new_token = crypt_str(&create_person.unwrap().ID.clone(), &keys.1, &keys.2);
    let new_token = encryption::BigInt::non_a7_u32_vec_to_exp_string(&new_token.parts);
    match auth_query {
        Ok(_) => HttpResponse::Ok().json(json!({
                "status": "success",
                "data": new_token
            }))
        ,
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "Insert Auth error",
            "message": e.to_string()
        }))
    }
}

pub async fn login_with_token(token: Option<String>, data: &web::Data<AppState>) -> Result<String, String>
{
    if token.is_none() { return Err(String::from("No valid login data was send")); };

    let token = token.unwrap();
    let token_to_decrypt = encryption::BigInt { parts: encryption::BigInt::exp_str_to_u32_vec(&token) };
    let keys = generate_key();
    let decrypted_token = crypt(&token_to_decrypt,&keys.0,&keys.2);
    let decrypted_token = encryption::BigInt::a7_u32_vec_to_string(&decrypted_token.parts);println!("Decrypted lwt: {}", decrypted_token.clone());

    let auth_query =
        sqlx::query_as!(Authentication, "SELECT * FROM AUTHENTICATION WHERE PERSON_ID = ?", decrypted_token)
            .fetch_one(&data.db)
            .await;

    if auth_query.is_err() { return Err(auth_query.unwrap_err().to_string()); };

    let last_login = auth_query.unwrap().LAST_LOGIN;
    let seconds_since_last_login = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() - last_login;

    let refresh_time_in_minutes = 15;
    if seconds_since_last_login / 60 > refresh_time_in_minutes {
        return Err("Token timed out".to_string());
    }

    let refresh_last_login_query =
        sqlx::query("UPDATE AUTHENTICATION SET LAST_LOGIN = ?")
            .bind(SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs())
            .execute(&data.db)
            .await;

    match refresh_last_login_query {
        Ok(auth) => Ok(token),
        Err(e) => Err(e.to_string())
    }
}

#[post("/login")]
pub async fn login_handler(body: web::Json<Login>, data: web::Data<AppState>) -> impl Responder
{

    if body.password.is_none() {
        return match login_with_token(body.token.clone(), &data).await {
            Ok(token) => HttpResponse::Ok().json(json!({
                "status": "success",
                "New Token": token
            })),
            Err(e) => HttpResponse::BadRequest().json(json!({
                "status": "Unauthorized with token",
                "message": e
            }))
        }
    }

    let password = body.password.as_ref().clone().unwrap();

    let email_query = sqlx::query("SELECT * FROM PERSON WHERE EMAIL = ?")
        .bind(&body.email)
        .fetch_one(&data.db)
        .await;
    if email_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Fetch email error",
        "message": email_query.unwrap_err().to_string()
    }))}

    let pw_as_u32 = password.chars().into_iter().map(|c| c as u32).collect::<Vec<u32>>();

    let hashed_password = hash(&pw_as_u32);

    let password_query = sqlx::query_as!(Authentication, "SELECT * FROM AUTHENTICATION WHERE AUTH = ?",hashed_password)
        .fetch_one(&data.db)
        .await;

    let keys = generate_key();
    let new_token = crypt_str(&password_query.as_ref().clone().unwrap().PERSON_ID.clone(),&keys.1,&keys.2);
    let new_token = encryption::BigInt::non_a7_u32_vec_to_exp_string(&new_token.parts);
    match password_query {
        Ok(_) => HttpResponse::Ok().json(json!({
            "status": "success",
            "New_Token": new_token
        })),
        Err(_) => HttpResponse::InternalServerError().json(json!({
            "status": "Fetch login error",
            "message": "Wrong password"
        }))
    }
}
