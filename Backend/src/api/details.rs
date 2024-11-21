use crate::model::details::*;
use crate::AppState;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};

#[get("/details")]
pub async fn details_list_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(
        Details,
        r#"SELECT * FROM DETAILS"#
    )
        .fetch_all(&data.db)
        .await;

    match result {
        Ok(details) => {
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

            HttpResponse::Ok().json(json!({
                "status": "success",
                "results": details_response.len(),
                "data": details_response,
            }))
        }
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Details: {}", e),
            }))
        }
    }
}

#[get("/details/{id}")]
pub async fn details_get_handler(
    data: web::Data<AppState>,
    path: web::Path<String>
) -> impl Responder {
    let details_id = path.into_inner();

    let result = sqlx::query_as!(
        Details,
        r#"SELECT * FROM DETAILS WHERE ID = ?"#,
        details_id
    )
        .fetch_one(&data.db)
        .await;

    match result {
        Ok(detail) => {
            HttpResponse::Ok().json(json!({
                "status": "success",
                "data": {
                    "ID": detail.ID,
                    "LOCATION_ID": detail.LOCATION_ID,
                    "CONTACTPERSON_ID": detail.CONTACTPERSON_ID,
                    "NAME": detail.NAME,
                    "START": detail.START,
                    "END": detail.END,
                }
            }))
        }
        Err(e) => {
            if e.to_string().contains("no rows returned by a query that expected to return at least one row") {
                HttpResponse::NotFound().json(json!({
                    "status": "error",
                    "message": "Details not found",
                }))
            } else {
                HttpResponse::InternalServerError().json(json!({
                    "status": "error",
                    "message": format!("Failed to fetch Details: {}", e),
                }))
            }
        }
    }
}

#[post("/details")]
pub async fn details_create_handler(body: web::Json<CreateDetails>, data:web::Data<AppState>) -> impl Responder {
    let new_details_id: Uuid = Uuid::new_v4();

    let query = sqlx::query(
        r#"INSERT INTO DETAILS (ID, LOCATION_ID, CONTACTPERSON_ID, NAME, START, END) VALUES (?, ?, ?, ?, ?, ?)"#)
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