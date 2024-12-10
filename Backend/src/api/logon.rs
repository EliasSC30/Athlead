use std::time::{SystemTime, UNIX_EPOCH};
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use crate::api::encryption::encryption::{crypt_str, generate_key, hash};
use crate::api::person::create_person;
use crate::AppState;
use crate::model::logon::{Person_ID_Wrapper, Login, Register, Authentication};
use crate::model::person::{CreatePerson, Person};

#[post("/register")]
pub async fn register_handler(body: web::Json<Register>, data: web::Data<AppState>) -> impl Responder
{
    if body.email.len() != 8 || body.password.len() != 8 {
        return HttpResponse::BadRequest().json(json!({
            "status": "Invalid login error",
            "message": "Email and password have to be exactly 8 character"
        }))
    }

    let password = body.password.clone();

    let pw_as_utf7 = password.chars().into_iter().map(|c| c as u8).collect::<Vec<u8>>();
    let mut chars = [0u8;8];

    for i in 0..8
    {
        chars[i] = pw_as_utf7[i];
    }

    let hashed_password = hash(&chars);

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
        .bind(&create_person.unwrap().ID)
        .bind(&hashed_password)
        .bind(SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs().to_string())
        .execute(&data.db)
        .await;

    let keys = generate_key(); let d = crypt_str(&body.email.clone(), keys.1, keys.2); println!("{:?}", d);

    let new_token_ar = crypt_str(&body.email.clone(), keys.1, keys.2);
    let mut new_token = String::from("");
    for index in 0..8
    {
        new_token.push(new_token_ar[index] as char);
    }

    println!("New token length: {:?}", new_token.len());

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
    let keys = generate_key();
    let decrypted_token = crypt_str(&token, keys.0, keys.2);
    let email = String::from_utf8_lossy(&decrypted_token).to_string();

    let person_query = sqlx::query_as!(Person, "SELECT * FROM PERSON WHERE EMAIL = ?",email.clone())
        .fetch_one(&data.db)
        .await;
    if person_query.is_err() { return Err(person_query.unwrap_err().to_string()); };

    let auth_query =
        sqlx::query_as!(Authentication, "SELECT * FROM AUTHENTICATION WHERE PERSON_ID = ?", person_query.unwrap().ID)
            .fetch_one(&data.db)
            .await;

    if auth_query.is_err() { return Err(auth_query.unwrap_err().to_string()); };

    let last_login = auth_query.unwrap().LAST_LOGIN;
    let seconds_since_last_login = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() - last_login;

    let refresh_time_in_minutes = 15;
    if seconds_since_last_login * 60 > refresh_time_in_minutes {
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
    if body.email.len() != 8 {
        return HttpResponse::BadRequest().json(json!({
            "status": "Invalid login error",
            "message": "Email and password have to be exactly 8 character"
        }))
    }

    if body.password.is_none() {
        return match login_with_token(body.token.clone(), &data).await {
            Ok(token) => HttpResponse::Ok().json(json!({
                "status": "success",
                "New Token": token
            })),
            Err(_) => HttpResponse::BadRequest().json(json!({
                "status": "Unauthorized",
                "message": "Bad token and no password provided to create new one"
            }))
        }
    }

    let password = body.password.as_ref().clone().unwrap();

    if password.len() != 8 {
        return HttpResponse::BadRequest().json(json!({
            "status": "Invalid login error",
            "message": "Email and password have to be exactly 8 character"
        }))
    }

    let email_query = sqlx::query("SELECT * FROM PERSON WHERE EMAIL = ?")
        .bind(&body.email)
        .fetch_one(&data.db)
        .await;
    if email_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Fetch email error",
        "message": email_query.unwrap_err().to_string()
    }))}

    let pw_as_utf7 = password.chars().into_iter().map(|c| c as u8).collect::<Vec<u8>>();
    let mut chars = [0u8;8];
    for i in 0..8
    {
        chars[i] = pw_as_utf7[i];
    }

    let hashed_password = hash(&chars);

    let password_query = sqlx::query("SELECT * FROM AUTHENTICATION WHERE AUTH = ?")
        .bind(&hashed_password)
        .fetch_one(&data.db)
        .await;



    let keys = generate_key();
    match password_query {
        Ok(_) => HttpResponse::Ok().json(json!({
            "status": "success",
            "New_Token": String::from_utf8_lossy(&crypt_str(&body.email.clone(), keys.1, keys.2)).to_string()
        })),
        Err(_) => HttpResponse::InternalServerError().json(json!({
            "status": "Fetch login error",
            "message": "Wrong password"
        }))
    }
}
