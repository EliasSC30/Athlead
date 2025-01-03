use actix_web::{get, HttpMessage, HttpRequest, HttpResponse, Responder};
use crate::model::person::Person;
use serde_json::json;

#[get("/loggedin")]
pub async fn get_logged_in_handler(req: HttpRequest) -> impl Responder {
    let container = req.extensions();
    let user = container.get::<Person>();

    match user {
        Some(person) => HttpResponse::Ok().json(json!({
            "is_logged_in": true,
            "person": serde_json::to_value(person).unwrap()
        })),
        None => HttpResponse::Ok().json(json!({
            "is_logged_in": false,
            "person": ""
        }))
    }
}