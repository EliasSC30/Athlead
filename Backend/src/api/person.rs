use crate::model::person::*;
use crate::AppState;
use actix_web::{get, post,patch, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};
use std::fmt;


#[patch("/persons/{id}")]
pub async fn persons_update_handler(body: web::Json<UpdatePerson>,
                                   data: web::Data<AppState>,
                                   path: web::Path<String>)
    -> impl Responder
{
    let person_id = path.into_inner();

    let update_request = body.into_inner();
    let is_role_update = update_request.ROLE.is_some();
    let is_contact_info_update = update_request.CONTACTINFO_ID.is_some();
    if  !is_role_update && !is_contact_info_update {
        return HttpResponse::BadRequest().json({});
    }

    let mut update_as_number = 0;
    if is_role_update { update_as_number += 1; }
    if is_contact_info_update { update_as_number += 2; }
    let mut updated_ci_id = String::from("");
    let mut updated_role = String::from("");

    let result_str = match update_as_number {
        1 => {
            updated_role = update_request.ROLE.unwrap().to_string();
            format!("ROLE = '{}'", updated_role)
        },
        2 => {
            updated_ci_id = update_request.CONTACTINFO_ID.unwrap().to_string();
            format!("CONTACTINFO_ID = '{}'", updated_ci_id)
        },
        3 => {
            updated_role = update_request.ROLE.unwrap().to_string();
            updated_ci_id = update_request.CONTACTINFO_ID.unwrap().to_string();
            format!("CONTACTINFO_ID = '{}', ROLE = '{}'", updated_ci_id, updated_role)
        },
        _ => { String::from("") }
    };


    let query = format!("UPDATE PERSON SET {} WHERE ID = ?", result_str);

    println!("{}",query.clone());

    let result = sqlx::query(query.as_str())
        .bind(person_id.clone())
        .execute(&data.db).await;

    match result {
        Ok(person) => {
            HttpResponse::Ok().json(json!(
            {
                    "status": "success",
                    "updatedPerson": {
                        "ID": person_id,
                        "NEW_ROLE": updated_role,
                        "NEW_CONTACT_INFO_ID": updated_ci_id,
                        }
            }))
        }
        Err(err) => {
            HttpResponse::InternalServerError().json(json!({"status" : format!("{}", err.to_string()) }))
        }
    }

}


#[get("/persons")]
pub async fn persons_list_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(
        Person,
        "SELECT * FROM PERSON"
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
        "SELECT * FROM PERSON WHERE ID = ?",
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

    HttpResponse::Created().json(json!({
        "status": "success",
        "message": "Person created successfully!",
        "data": json!({
            "ID": new_person_id.to_string(),
            "CONTACTINFO_ID": body.CONTACTINFO_ID,
            "ROLE": body.ROLE
        })
    }))
}