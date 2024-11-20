use crate::model::sportfest::*;
use crate::AppState;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};

#[get("/sportfests")]
pub async fn sportfest_list_handler(data: web::Data<AppState>) -> impl Responder {


    let sportfests: Vec<Sportfest> = sqlx::query_as!(
        Sportfest,
        r#"SELECT * FROM Sportfest"#)
        .fetch_all(&data.db)
        .await
        .map_err(|e| {
           return HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": "Failed to fetch sportfests, with error: ".to_owned() + &e.to_string(),
            }))
        })
        .unwrap();

    let sportfest_response = sportfests.into_iter().map(|sportfest| {
        json!({
            "id": sportfest.ID,
            "details_id": sportfest.DETAILS_ID,
        })
    }).collect::<Vec<serde_json::Value>>();

    return HttpResponse::Ok().json(json!({
        "status": "success",
        "results": sportfest_response.len(),
        "data": sportfest_response,
    }));
}

#[post("/sportfests")]
pub async fn sportfest_create_handler(body: web::Json<CreateSportfest>, data:web::Data<AppState>) -> impl Responder {
    let new_sportfest_id: Uuid = Uuid::new_v4();
    let query = sqlx::query(
        r#"INSERT INTO sportfest (ID, DETAILS_ID) VALUES (?, ?)"#)
        .bind(new_sportfest_id.to_string())
        .bind(body.DETAILS_ID.to_string())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string());
    if let Err(e) = query {
        if e.contains("foreign key constraint fails") {
            return HttpResponse::BadRequest().json(json!({
                "status": "error",
                "message": "Failed to create sportfest, because details_id does not exist",
            }))
        }
        return HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": "Failed to create sportfest, with error: ".to_owned() + &e.to_string(),
        }))
    }

    return HttpResponse::Created().json(json!({
        "status": "success",
        "message": "Sportfest created successfully!",
        "data": json!({
            "id": new_sportfest_id.to_string(),
            "details_id": body.DETAILS_ID,
        })
    }));
}