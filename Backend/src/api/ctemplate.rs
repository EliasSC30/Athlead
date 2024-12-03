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

#[get("/ctemplates/{id}")]
pub async fn ctemplates_get_by_id_handler(data: web::Data<AppState>, path: web::Path<String>) -> impl Responder {
    let result = sqlx::query_as!(CTemplate, "SELECT * FROM C_TEMPLATE WHERE ID = ?", path.into_inner())
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
                "data": serde_json::to_value(contest_response.get(0)).unwrap(),
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

pub async fn create_contest(contest: &CreateCTemplate, data: &web::Data<AppState>) -> Result<CTemplate, String> {
    let template_id = Uuid::new_v4();

    match sqlx::query(
        "INSERT INTO C_TEMPLATE (ID, NAME, DESCRIPTION, GRADERANGE, EVALUATION, UNIT) VALUES (?, ?, ?, ?, ?, ?)")
        .bind(template_id.clone().to_string())
        .bind(contest.NAME.clone())
        .bind(contest.DESCRIPTION.as_ref().clone().or(Some(&"".to_string())))
        .bind(contest.GRADERANGE.as_ref().clone().or(Some(&"".to_string())))
        .bind(contest.EVALUATION.clone())
        .bind(contest.UNIT.clone())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string()) {
        Ok(_) => Ok(
                CTemplate {
                ID: template_id.to_string(),
                NAME: contest.NAME.clone(),
                DESCRIPTION: contest.DESCRIPTION.clone(),
                GRADERANGE: contest.GRADERANGE.clone(),
                EVALUATION: contest.EVALUATION.clone(),
                UNIT: contest.UNIT.clone()
        }),
        Err(e) => Err(e.to_string())
    }
}

#[post("/ctemplates")]
pub async fn create_ctemplate_handler(body: web::Json<CreateCTemplate>, data:web::Data<AppState>) -> impl Responder {
    let query = create_contest(&body.0, &data).await;
    match query {
        Ok(result) => {
            HttpResponse::Created().json(json!({
                "status": "success",
                "message": "ContactInfo created successfully!",
                "data": serde_json::to_value(result).unwrap()
                }))
        },
        Err(e) => { HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": "Failed to create contest with error: ".to_owned() + &e.to_string()
            }))
        }
    }
}

