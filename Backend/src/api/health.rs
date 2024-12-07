use actix_web::{get, HttpResponse, Responder};
use serde_json::json;
use chrono::prelude::*;
use crate::api::encryption::encryption::{crypt_many, generate_key, BigInt};

#[get("/health")]
pub async fn health_checker_handler() -> impl Responder {
    const MESSAGE: &str = "Server is running!";
    let datetime: DateTime<Local> = Local::now();



    let (e,d,n) = generate_key();


    let secret = vec!['J' as u128, 'A' as u128, 'N' as u128];

    println!("{:?}", secret);
    let encrypted = crypt_many(secret, e, n);
    println!("{:?}", encrypted);

    let decrypted = crypt_many(encrypted, d, n);
    println!("{:?}", decrypted);


    HttpResponse::Ok().json(json!({"status": "success","message": MESSAGE, "time": datetime}))
}