use crate::model::sportfest::*;
use crate::AppState;
use actix_web::{get, post, patch, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};

#[get("/sportfests")]
pub async fn sportfests_list_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(
        Sportfest,
        r#"SELECT * FROM Sportfest"#
    )
        .fetch_all(&data.db)
        .await;

    match result {
        Ok(sportfests) => {
            let sportfest_response = sportfests.into_iter().map(|sportfest| {
                json!({
                    "id": sportfest.ID,
                    "details_id": sportfest.DETAILS_ID,
                })
            }).collect::<Vec<serde_json::Value>>();

            HttpResponse::Ok().json(json!({
                "status": "success",
                "results": sportfest_response.len(),
                "data": sportfest_response,
            }))
        }
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch sportfests: {}", e),
            }))
        }
    }
}


#[get("/sportfests/{id}")]
pub async fn sportfests_get_handler(
    data: web::Data<AppState>,
    path: web::Path<String>
) -> impl Responder {
    let sportfest_id = path.into_inner();

    let result = sqlx::query_as!(
        Sportfest,
        r#"SELECT * FROM SPORTFEST WHERE ID = ?"#,
        sportfest_id
    )
        .fetch_one(&data.db)
        .await;

    match result {
        Ok(sportfest) => {
            HttpResponse::Ok().json(json!({
                "status": "success",
                "data": {
                    "id": sportfest.ID,
                    "details_id": sportfest.DETAILS_ID,
                }
            }))
        }
        Err(e) => {
            if e.to_string().contains("no rows returned by a query that expected to return at least one row") {
                HttpResponse::NotFound().json(json!({
                    "status": "error",
                    "message": "Sportfests not found",
                }))
            } else {
                HttpResponse::InternalServerError().json(json!({
                    "status": "error",
                    "message": format!("Failed to fetch Sportfests: {}", e),
                }))
            }
        }
    }
}

#[post("/sportfests")]
pub async fn sportfests_create_handler(body: web::Json<CreateSportfest>, data:web::Data<AppState>) -> impl Responder {
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

    HttpResponse::Created().json(json!({
        "status": "success",
        "message": "Sportfest created successfully!",
        "data": json!({
            "id": new_sportfest_id.to_string(),
            "details_id": body.DETAILS_ID,
        })
    }))
}

#[patch("/sportfests/{id}")]
pub async fn sportfests_update_handler(body: web::Json<UpdateSportfest>,
                                       data: web::Data<AppState>,
                                       path: web::Path<String>)
    -> impl Responder
{
    let sportfest_id = path.into_inner();

    let updates_details = body.DETAILS_ID.is_some();


    let nr_of_updates : u8 =
        [updates_details as u8].iter().sum();
    println!("Updates details: {}", nr_of_updates);
    if nr_of_updates == 0 { return HttpResponse::BadRequest().json(json!({"status": "Invalid Body Error"})); }

    let mut build_update_query = String::from("SET ");

    if updates_details {
        build_update_query += format!("DETAILS_ID = '{}', ", body.DETAILS_ID.clone().unwrap()).as_str();
    }

    // Remove excessive ', '
    build_update_query.truncate(build_update_query.len().saturating_sub(2));

    let result = format!("UPDATE SPORTFEST {} WHERE ID = '{}'", build_update_query, sportfest_id);

    match sqlx::query(result.as_str()).execute(&data.db).await {
        Ok(_) => {
            HttpResponse::Ok().json(
                json!(
                                {
                                    "status": "success",
                                    "result": json!({
                                        "ID" : sportfest_id,
                                        "DETAILS_ID":     if updates_details { body.DETAILS_ID.clone().unwrap() }
                                                          else { String::from("") },
                                    }),
                                }))}
        Err(e) => {
            HttpResponse::InternalServerError().json(
                json!(
                                {
                                    "status": "error",
                                    "message": &e.to_string(),
                                }))
        }
    }
}
