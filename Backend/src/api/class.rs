use crate::model::class::*;
use crate::AppState;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;

#[get("/classes")]
pub async fn class_list_handler(data: web::Data<AppState>) -> impl Responder {
    let class: Vec<Class> = sqlx::query_as!(
       Class,
       r#"SELECT * FROM Classes"#)
        .fetch_all(&data.db)
        .await
        .unwrap();

    let class_response = class.into_iter().map(|class| {
        json!({
            "id": class.id,
            "grade": class.grade,
            "section": class.section,
            "teacher_id": class.teacher_id,
            "created_at": class.created_at,
        })
    }).collect::<Vec<serde_json::Value>>();

    HttpResponse::Ok().json(json!({
        "status": "success",
        "results": class_response.len(),
        "data": class_response,
    }))

}