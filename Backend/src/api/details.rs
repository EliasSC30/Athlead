use crate::model::details::*;
use crate::AppState;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};

#[get("/details")]
pub async fn details_list_handler(data: web::Data<AppState>) -> impl Responder {

    let details: Vec<Details> = sqlx::query_as!(
        Details,
        r#"SELECT * FROM Details"#)
        .fetch_all(&data.db)
        .await
        .map_err(|e| {
            return HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": "Failed to fetch Details, with error: ".to_owned() + &e.to_string(),
            }))
        })
        .unwrap();

    let details_response = details.into_iter().map(|details| {
        json!({
            "ID": details.ID,
            "LOCATION_ID": details.LOCATION_ID,
            "CONTACTPERSON_ID": details.CONTACTPERSON_ID,
            "NAME": details.NAME,
            "START": details.START,
            "END": details.END,
        })
    }).collect::<Vec<serde_json::Value>>();

    return HttpResponse::Ok().json(json!({
        "status": "success",
        "results": details_response.len(),
        "data": details_response,
    }));
}


#[post("/details")]
pub async fn details_create_handler(body: web::Json<CreateDetails>, data:web::Data<AppState>) -> impl Responder {
    let new_details_id: Uuid = Uuid::new_v4();

    let query = sqlx::query(
        r#"INSERT INTO Details (ID, LOCATION_ID, CONTACTPERSON_ID, NAME, START, END) VALUES (?, ?, ?, ?, ?, ?)"#)
        .bind(new_details_id.to_string())
        .bind(body.LOCATION_ID.to_string())
        .bind(body.CONTACTPERSON_ID.to_string())
        .bind(body.NAME.clone())
        .bind(body.START)
        .bind(body.END)
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string());
    if let Err(e) = query {
        if e.contains("foreign key constraint fails") {
            return HttpResponse::BadRequest().json(json!({
                "status": "error",
                "message": "Failed to create Details, because location_id or contactperson_id does not exist",
            }))
        }
        return HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": "Failed to create Details, with error: ".to_owned() + &e.to_string(),
        }))
    }

    return HttpResponse::Created().json(json!({
        "status": "success",
        "message": "Details created successfully!",
        "data": json!({
            "ID": new_details_id.to_string(),
            "LOCATION_ID": body.LOCATION_ID,
            "CONTACTPERSON_ID": body.CONTACTPERSON_ID,
            "NAME": body.NAME,
            "START": body.START,
            "END": body.END

        })
    }));
}