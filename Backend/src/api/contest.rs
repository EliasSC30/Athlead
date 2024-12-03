use crate::model::contest::*;
use crate::AppState;
use actix_web::{get, post, patch, web, HttpResponse, Responder};
use env_logger::builder;
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::mysql::MySqlQueryResult;
use uuid::{Uuid};
use crate::model::contactinfo::CreateContactInfo;

#[get("/contests")]
pub async fn contests_get_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(Contest, "SELECT * FROM CONTEST")
        .fetch_all(&data.db)
        .await;

    match result {
        Ok(details) => {
            let contest_response = details.into_iter().map(|contest_info| {
                json!({
                    "ID": contest_info.ID,
                    "SPORTFEST_ID": contest_info.SPORTFEST_ID,
                    "DETAILS_ID": contest_info.DETAILS_ID,
                    "CONTESTRESULT_ID": contest_info.CONTESTRESULT_ID,
                })
            }).collect::<Vec<serde_json::Value>>();

            HttpResponse::Ok().json(json!({
                "status": "success",
                "results": contest_response.len(),
                "data": contest_response,
            }))
        }
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Contests: {}", e),
            }))
        }
    }
}

pub async fn create_contest(contest: CreateContest, data: &web::Data<AppState>) -> Result<MySqlQueryResult, String> {
    let contest_id: Uuid = Uuid::new_v4();

    sqlx::query(
        "INSERT INTO CONTEST (ID, SPORTFEST_ID, DETAILS_ID, CONTESTRESULT_ID) VALUES (?, ?, ?, ?)")
        .bind(contest_id.to_string())
        .bind(contest.SPORTFEST_ID.clone())
        .bind(contest.DETAILS_ID.clone())
        .bind(contest.CONTESTRESULT_ID.clone())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string())
}

#[post("/contests")]
pub async fn contest_create_handler(body: web::Json<CreateContest>, data:web::Data<AppState>) -> impl Responder {
    let query = create_contest(body.0, &data).await;
    match query {
        Ok(result) => {
            HttpResponse::Created().json(json!({
                "status": "success",
                "message": "ContactInfo created successfully!",
                "data": ""
                }))
        },
        Err(e) => { HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": "Failed to create contest with error: ".to_owned() + &e.to_string()
            }))
        }
    }
}

