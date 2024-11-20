use crate::model::person::*;
use crate::AppState;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};

#[get("/persons")]
pub async fn person_list_handler(data: web::Data<AppState>) -> impl Responder {

    let persons: Vec<Person> = sqlx::query_as!(
        Person,
        r#"SELECT * FROM PERSON"#)
        .fetch_all(&data.db)
        .await
        .map_err(|e| {
            return HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": "Failed to fetch Details, with error: ".to_owned() + &e.to_string(),
            }))
        })
        .unwrap();

    let persons_response = persons.into_iter().map(|details| {
        json!({
            "ID": details.ID,
            "CONTACTINFO_ID": details.CONTACTINFO_ID,
            "ROLE": details.ROLE
        })
    }).collect::<Vec<serde_json::Value>>();

    return HttpResponse::Ok().json(json!({
        "status": "success",
        "results": persons_response.len(),
        "data": persons_response,
    }));
}

#[post("/person")]
pub async fn person_create_handler(body: web::Json<CreatePerson>, data:web::Data<AppState>) -> impl Responder {
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