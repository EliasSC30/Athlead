use crate::model::contestresult::*;
use crate::model::contest::*;
use crate::{model, AppState};
use actix_web::{get, post, patch, web, HttpResponse, Responder};
use env_logger::builder;
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::mysql::{MySqlQueryResult, MySqlRow};
use sqlx::Row;
use uuid::{Uuid};
use crate::api::metric::{create_metric};
use crate::model::metric::{CreateMetric, LengthUnit, Metric, TimeUnit, WeightUnit};

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

#[post("/contests/{id}/contestresults")]
pub async fn create_result_for_contest_handler(body: web::Json<CreateContest>, data:web::Data<AppState>) -> impl Responder {
    let contest_id: Uuid = Uuid::new_v4();

    let query = sqlx::query(
        "INSERT INTO CONTEST (ID, SPORTFEST_ID, DETAILS_ID, CONTESTRESULT_ID) VALUES (?, ?, ?, ?)")
        .bind(contest_id.to_string())
        .bind(body.SPORTFEST_ID.clone())
        .bind(body.DETAILS_ID.clone())
        .bind(body.CONTESTRESULT_ID.clone())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string());
    if let Err(e) = query {
        return HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": "Failed to create contest with error: ".to_owned() + &e.to_string(),
        }))
    }

    HttpResponse::Created().json(json!({
        "status": "success",
        "message": "ContactInfo created successfully!",
        "data": json!({
            "ID": contest_id.to_string(),
            "SPORTFEST_ID": body.SPORTFEST_ID,
            "DETAILS_ID": body.DETAILS_ID,
            "CONTESTRESULT_ID": body.CONTESTRESULT_ID,
        })
    }))
}
