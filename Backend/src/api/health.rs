use actix_web::{get, HttpResponse, Responder};
use serde_json::json;
use chrono::prelude::*;
use crate::api::encryption::encryption::{crypt_str, generate_key, BigInt};

#[get("/health")]
pub async fn health_checker_handler() -> impl Responder {
    const MESSAGE: &str = "Server is running!";
    let datetime: DateTime<Local> = Local::now();

    HttpResponse::Ok().json(json!({"status": "success","message": MESSAGE, "time": datetime}))
}