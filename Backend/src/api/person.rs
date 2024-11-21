use crate::model::person::*;
use crate::AppState;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};

#[get("/persons")]
pub async fn persons_list_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(
        Person,
        r#"SELECT * FROM PERSON"#
    )
        .fetch_all(&data.db)
        .await;

    match result {
        Ok(persons) => {
            let persons_response = persons.into_iter().map(|person| {
                json!({
                    "ID": person.ID,
                    "CONTACTINFO_ID": person.CONTACTINFO_ID,
                    "ROLE": person.ROLE
                })
            }).collect::<Vec<serde_json::Value>>();

            HttpResponse::Ok().json(json!({
                "status": "success",
                "results": persons_response.len(),
                "data": persons_response,
            }))
        }
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch persons: {}", e),
            }))
        }
    }
}

#[get("/persons/{id}")]
pub async fn persons_get_handler(
    data: web::Data<AppState>,
    path: web::Path<String>
) -> impl Responder {
    let person_id = path.into_inner();

    let result = sqlx::query_as!(
        Person,
        r#"SELECT * FROM PERSON WHERE ID = ?"#,
        person_id
    )
        .fetch_one(&data.db)
        .await;

    match result {
        Ok(person) => {
            HttpResponse::Ok().json(json!({
                "status": "success",
                "data": {
                    "ID": person.ID,
                    "CONTACTINFO_ID": person.CONTACTINFO_ID,
                    "ROLE": person.ROLE
                }
            }))
        }
        Err(e) => {
            if e.to_string().contains("no rows returned by a query that expected to return at least one row") {
                HttpResponse::NotFound().json(json!({
                    "status": "error",
                    "message": "Persons not found",
                }))
            } else {
                HttpResponse::InternalServerError().json(json!({
                    "status": "error",
                    "message": format!("Failed to fetch Persons: {}", e),
                }))
            }
        }
    }
}

#[post("/persons")]
pub async fn persons_create_handler(body: web::Json<CreatePerson>, data:web::Data<AppState>) -> impl Responder {
    let new_person_id: Uuid = Uuid::new_v4();

    let query = sqlx::query(
        r#"INSERT INTO PERSON (ID, CONTACTINFO_ID, ROLE) VALUES (?, ?, ?)"#)
        .bind(new_person_id.to_string())
        .bind(body.CONTACTINFO_ID.clone())
        .bind(body.ROLE.to_string())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string());

    if let Err(e) = query {
        if e.contains("foreign key constraint fails") {
            return HttpResponse::BadRequest().json(json!({
                "status": "error",
                "message": "Failed to create PERSON, because CONTACTINFO_ID does not exist",
            }))
        }
        return HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": "Failed to create Person, with error: ".to_owned() + &e.to_string(),
        }))
    }

    return HttpResponse::Created().json(json!({
        "status": "success",
        "message": "Person created successfully!",
        "data": json!({
            "ID": new_person_id.to_string(),
            "CONTACTINFO_ID": body.CONTACTINFO_ID,
            "ROLE": body.ROLE
        })
    }));
}