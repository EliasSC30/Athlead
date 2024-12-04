use crate::model::contestresult::*;
use crate::model::contest::*;
use crate::{AppState};
use actix_web::{get, post, patch, web, HttpResponse, Responder};
use serde_json::json;
use sqlx::Row;
use uuid::{Uuid};

#[get("/contestresults")]
pub async fn get_contest_results_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(
        ContestResult,
        "SELECT * FROM CONTESTRESULT"
        )
        .fetch_all(&data.db).await;


    match result {
        Ok(values) => HttpResponse::Ok().json(json!({
                "status": "success",
                "results": values.len(),
                "data": serde_json::to_value(values).unwrap(),
            }))
        ,
        Err(e) => HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Contests: {}", e),
            }))

    }
}
