use std::ops::Add;
use std::time::{SystemTime, UNIX_EPOCH};
use actix_web::{cookie, get, post, web, Error, HttpMessage, HttpRequest, HttpResponse, Responder};
use actix_web::cookie::{Cookie, Expiration};
use actix_web::cookie::Expiration::DateTime;
use actix_web::cookie::time::PrimitiveDateTime;
use actix_web::web::Data;
use serde_json::json;
use sqlx::MySqlPool;
use crate::api::encryption::encryption;
use crate::api::person::create_person;
use crate::model::logon::{Login, Register, Authentication};
use crate::model::person::{CreatePerson, Person};
use crate::model::parent_children::{ParentChildren};

#[get("/parents/children")]
pub async fn parents_get_children_handler(req: HttpRequest, db: Data<MySqlPool>) -> impl Responder {
    let container = req.extensions();
    let user = container.get::<Person>();
    if user.is_none() { return HttpResponse::InternalServerError().json(json!({
        "status": "User was none error",
        "message": "Should not happen..",
    }))};
    let user = user.unwrap();

    let parents_query =
        sqlx::query_as!(ParentChildren, "SELECT * FROM PARENT WHERE PARENT_ID = ?", user.ID)
            .fetch_all(db.as_ref())
            .await;

    if parents_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Internal server error",
    })); };

    HttpResponse::Ok().json(json!({
        "status": "success",
        "data": serde_json::to_value(parents_query.unwrap()).unwrap()
    }))
}