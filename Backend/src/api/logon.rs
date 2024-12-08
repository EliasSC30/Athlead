use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use crate::api::encryption::encryption::{crypt_str, generate_key, hash};
use crate::api::person::create_person;
use crate::AppState;
use crate::model::logon::{Person_ID_Wrapper, Login, Register};
use crate::model::person::CreatePerson;

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

    let email_query = sqlx::query("SELECT * FROM CONTACTINFO WHERE EMAIL = ?")
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

    let auth_query = sqlx::query("INSERT INTO AUTHENTICATION (AUTH, PERSON_ID) VALUES (?, ?)")
        .bind(&hashed_password)
        .bind(&create_person.unwrap().ID)
        .execute(&data.db)
        .await;

    let keys = generate_key();

    match auth_query {
        Ok(_) => HttpResponse::Ok().json(json!({
                "status": "success",
                "data": String::from_utf8_lossy(&crypt_str(&body.email.clone(), keys.1, keys.2)).to_string()
            }))
        ,
        Err(_) => HttpResponse::InternalServerError().json(json!({
            "status": "Fetch person id error",
            "message": String::from("")
        }))
    }
}

#[get("/login")]
pub async fn login_handler(body: web::Json<Login>, data: web::Data<AppState>) -> impl Responder
{
    if body.email.len() != 8 || body.password.len() != 8 {
        return HttpResponse::BadRequest().json(json!({
            "status": "Invalid login error",
            "message": "Email and password have to be exactly 8 character"
        }))
    }

    let email_query = sqlx::query("SELECT * FROM CONTACTINFO WHERE EMAIL = ?")
        .bind(&body.email)
        .fetch_one(&data.db)
        .await;
    if email_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Fetch email error",
        "message": email_query.unwrap_err().to_string()
    }))}

    let password = body.password.clone();
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
