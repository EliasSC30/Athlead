use actix_web::{get, HttpResponse, Responder};
use serde_json::json;
use chrono::prelude::*;
use crate::api::encryption::encryption::{crypt_str, crypt, generate_key, BigInt};

#[get("/health")]
pub async fn health_checker_handler() -> impl Responder {
    const MESSAGE: &str = "Server is running!";
    let datetime: DateTime<Local> = Local::now();

    let (e,d,n) = generate_key();
    let str = String::from("d898348c-24cd-4b37-8402-b142f9f5d2cd");
    let encrypted = crypt_str(&str, &d, &n);
    let decrypted = crypt(&encrypted, &e, &n);
    let decrypted = BigInt::a7_u32_vec_to_string(&decrypted.parts);
    assert_eq!(decrypted, str);


    HttpResponse::Ok().json(json!({"status": "success","message": MESSAGE, "time": datetime}))
}