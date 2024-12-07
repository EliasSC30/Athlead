use actix_web::{get, HttpResponse, Responder};
use serde_json::json;
use chrono::prelude::*;
use crate::api::encryption::encryption::{crypt_str, generate_key, BigInt};

#[get("/health")]
pub async fn health_checker_handler() -> impl Responder {
    const MESSAGE: &str = "Server is running!";
    let datetime: DateTime<Local> = Local::now();


    let (e,d,n) = generate_key();

    let secret: [u8;8] = "jan ;pwd".as_bytes().try_into().expect("Wrong size");

    println!("Before {:?}", secret);
    let encrypted = crypt_str(&secret, e, n);
    println!("After encryption{:?}", encrypted);

    let decrypted = crypt_str(&encrypted, d, n);
    println!("Decrypted {:?}", decrypted);


    HttpResponse::Ok().json(json!({"status": "success","message": MESSAGE, "time": datetime}))
}