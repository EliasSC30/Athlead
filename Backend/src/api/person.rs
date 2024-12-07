use crate::model::person::*;
use crate::AppState;
use actix_web::{get, post,patch, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};


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
        Ok(_) => {
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
pub async fn persons_get_all_handler(data: web::Data<AppState>) -> impl Responder {
    let query = sqlx::query_as!(
        Person,
        "SELECT * FROM PERSON"
    )
        .fetch_all(&data.db)
        .await;

    match query {
        Ok(persons) => HttpResponse::Ok().json(json!({
                "status": "success",
                "results": persons.len(),
                "data": serde_json::to_value(persons).unwrap(),
            }))
        ,
        Err(e) => HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch persons: {}", e),
            }))
    }
}

#[get("/persons/{id}")]
pub async fn persons_get_by_id_handler(
    data: web::Data<AppState>,
    path: web::Path<String>
) -> impl Responder {
    let person_id = path.into_inner();

    let query = sqlx::query_as!(
        Person,
        "SELECT * FROM PERSON WHERE ID = ?",
        person_id
    )
        .fetch_one(&data.db)
        .await;

    match query {
        Ok(person) => HttpResponse::Ok().json(json!({
                "status": "success",
                "data": serde_json::to_value(&person).unwrap(),
            }))
        ,
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": format!("Failed to fetch person: {}", e),
        }))
    }
}

#[post("/persons")]
pub async fn persons_create_handler(body: web::Json<CreatePerson>, data:web::Data<AppState>) -> impl Responder {
    let new_ci_id = Uuid::new_v4();
    let new_person_id = Uuid::new_v4();

    let ci_query = sqlx::query(
        "INSERT INTO CONTACTINFO (ID, FIRSTNAME, LASTNAME, EMAIL, PHONE, GRADE, BIRTH_YEAR) VALUES (?, ?, ?, ?, ?, ?, ?)")
        .bind(&new_ci_id.to_string())
        .bind(body.first_name.clone())
        .bind(body.last_name.clone())
        .bind(body.email.clone())
        .bind(body.phone.clone())
        .bind(body.grade.clone())
        .bind(body.birth_year.clone())
        .execute(&data.db)
        .await;

    if ci_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
        "message": ci_query.unwrap_err().to_string(),
    }))};

    let person_query = sqlx::query(
        "INSERT INTO PERSON (ID, CONTACTINFO_ID, ROLE) VALUES (?, ?, ?)")
        .bind(&new_person_id.to_string())
        .bind(new_ci_id.to_string())
        .bind(body.role.clone())
        .execute(&data.db)
        .await;

    match person_query {
        Ok(_) => HttpResponse::Ok().json(json!({
            "status": "success",
            "data": json!({
                    "ID": new_person_id,
                    "CONTACTINFO_ID": new_ci_id,
            })
        })),
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": format!("Failed to create person: {}", e),
        }))
    }
}