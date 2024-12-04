use crate::model::ctemplate::*;
use crate::AppState;
use actix_web::{get, post, patch, web, HttpResponse, Responder};

use serde_json::json;
use uuid::{Uuid};

#[get("/ctemplates")]
pub async fn ctemplates_get_all_handler(data: web::Data<AppState>) -> impl Responder {
    let query = sqlx::query_as!(CTemplate, "SELECT * FROM C_TEMPLATE")
        .fetch_all(&data.db)
        .await;

    match query {
        Ok(templates) => HttpResponse::Ok().json(json!({
                "status": "success",
                "results": templates.len(),
                "data": serde_json::to_value(&templates).unwrap(),
            }))
        ,
        Err(e) => HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Contests: {}", e),
            }))

    }
}

#[get("/ctemplates/{id}")]
pub async fn ctemplates_get_by_id_handler(data: web::Data<AppState>, path: web::Path<String>) -> impl Responder {
    let result = sqlx::query_as!(CTemplate, "SELECT * FROM C_TEMPLATE WHERE ID = ?", path.into_inner())
        .fetch_one(&data.db)
        .await;

    match result {
        Ok(templates) =>
            HttpResponse::Ok().json(json!({
                "status": "success",
                "data": serde_json::to_value(templates).unwrap(),
            }))
        ,
        Err(e) => HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Contests: {}", e),
            }))

    }
}

pub async fn create_ctemplate(contest: &CreateCTemplate, data: &web::Data<AppState>) -> Result<CTemplate, String> {
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
pub async fn ctemplate_create_handler(body: web::Json<CreateCTemplate>, data:web::Data<AppState>) -> impl Responder {
    let ctemplate = create_ctemplate(&body.0, &data).await;
    match ctemplate {
        Ok(result) => HttpResponse::Created().json(json!({
                "status": "success",
                "data": serde_json::to_value(result).unwrap()
                }))
        ,
        Err(e) => HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": e
            }))
    }
}

