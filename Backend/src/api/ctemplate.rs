use crate::model::ctemplate::*;
use crate::AppState;
use actix_web::{get, post, patch, web, HttpResponse, Responder};

use serde_json::json;
use sqlx::mysql::MySqlQueryResult;
use uuid::{Uuid};

#[get("/ctemplates")]
pub async fn ctemplates_get_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(CTemplate, "SELECT * FROM C_TEMPLATE")
        .fetch_all(&data.db)
        .await;

    match result {
        Ok(templates) => {
            let contest_response = templates.into_iter().map(|value| {
                json!({
                        "ID": value.ID,
                        "NAME": value.NAME,
                        "DESCRIPTION": value.DESCRIPTION,
                        "GRADERANGE": value.GRADERANGE,
                        "EVALUATION": value.EVALUATION,
                        "UNIT": value.UNIT
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

pub async fn create_contest(contest: CreateCTemplate, data: &web::Data<AppState>) -> Result<MySqlQueryResult, String> {
    let template_id: Uuid = Uuid::new_v4();

    sqlx::query(
        "INSERT INTO CONTEST (ID, SPORTFEST_ID, DETAILS_ID, CONTESTRESULT_ID) VALUES (?, ?, ?, ?)")
        .bind(template_id.to_string())
        .bind(contest.NAME.clone())
        .bind(contest.DESCRIPTION.clone())
        .bind(contest.GRADERANGE.clone())
        .bind(contest.UNIT.clone())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string())
}

#[post("/ctemplate")]
pub async fn ctemplate_create_handler(body: web::Json<CreateCTemplate>, data:web::Data<AppState>) -> impl Responder {
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

