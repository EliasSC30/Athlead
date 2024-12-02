use crate::model::contactinfo::*;
use crate::AppState;
use actix_web::{get, post, patch, web, HttpResponse, Responder};
use env_logger::builder;
use serde::{Deserialize, Serialize};
use serde_json::json;
use uuid::{Uuid};

#[get("/contactinfos")]
pub async fn contactinfos_list_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(
        ContactInfo,
        "SELECT * FROM CONTACTINFO"
    )
        .fetch_all(&data.db)
        .await;

    match result {
        Ok(details) => {
            let contactinfo_response = details.into_iter().map(|contactinfo| {
                json!({
                    "ID": contactinfo.ID,
                    "FIRSTNAME": contactinfo.FIRSTNAME,
                    "LASTNAME": contactinfo.LASTNAME,
                    "EMAIL": contactinfo.EMAIL,
                    "PHONE": contactinfo.PHONE,
                })
            }).collect::<Vec<serde_json::Value>>();

            HttpResponse::Ok().json(json!({
                "status": "success",
                "results": contactinfo_response.len(),
                "data": contactinfo_response,
            }))
        }
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch ContactInfo: {}", e),
            }))
        }
    }
}

#[get("/contactinfos/{id}")]
pub async fn contactinfos_get_handler(
    data: web::Data<AppState>,
    path: web::Path<String>
) -> impl Responder {
    let contactinfo_id = path.into_inner();

    let result = sqlx::query_as!(
        ContactInfo,
        r#"SELECT * FROM CONTACTINFO WHERE ID = ?"#,
        contactinfo_id
    )
        .fetch_one(&data.db)
        .await;

    match result {
        Ok(contactinfo) => {
            HttpResponse::Ok().json(json!({
                "status": "success",
                "data": {
                    "ID": contactinfo.ID,
                    "FIRSTNAME": contactinfo.FIRSTNAME,
                    "LASTNAME": contactinfo.LASTNAME,
                    "EMAIL": contactinfo.EMAIL,
                    "PHONE": contactinfo.PHONE,
                }
            }))
        }
        Err(e) => {
            if e.to_string().contains("no rows returned by a query that expected to return at least one row") {
                HttpResponse::NotFound().json(json!({
                    "status": "error",
                    "message": "ContactInfo not found",
                }))
            } else {
                HttpResponse::InternalServerError().json(json!({
                    "status": "error",
                    "message": format!("Failed to fetch ContactInfo: {}", e),
                }))
            }
        }
    }
}
#[post("/contactinfos")]
pub async fn contactinfos_create_handler(body: web::Json<CreateContactInfo>, data:web::Data<AppState>) -> impl Responder {
    let new_details_id: Uuid = Uuid::new_v4();

    let query = sqlx::query(
        r#"INSERT INTO CONTACTINFO (ID, FIRSTNAME, LASTNAME, EMAIL, PHONE) VALUES (?, ?, ?, ?, ?)"#)
        .bind(new_details_id.to_string())
        .bind(body.FIRSTNAME.clone())
        .bind(body.LASTNAME.clone())
        .bind(body.EMAIL.clone())
        .bind(body.PHONE.clone())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string());
    if let Err(e) = query {
        return HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": "Failed to create contactinfo with error: ".to_owned() + &e.to_string(),
        }))
    }

    HttpResponse::Created().json(json!({
        "status": "success",
        "message": "ContactInfo created successfully!",
        "data": json!({
            "ID": new_details_id.to_string(),
            "FIRSTNAME": body.FIRSTNAME,
            "LASTNAME": body.LASTNAME,
            "EMAIL": body.EMAIL,
            "PHONE": body.PHONE
        })
    }))
}

#[patch("/contactinfos/{id}")]
pub async fn contactinfos_update_handler(body: web::Json<UpdateContactInfo>,
                                         data:web::Data<AppState>,
                                         path: web::Path<String>)
-> impl Responder
{
    let ci_id = path.into_inner();

    let updates_first_name = body.FIRSTNAME.is_some();
    let updates_last_name = body.LASTNAME.is_some();
    let updates_email = body.EMAIL.is_some();
    let updates_phone = body.PHONE.is_some();

    let nr_of_updates : u8 =
        [updates_first_name as u8, updates_last_name as u8, updates_email as u8, updates_phone as u8].iter().sum();
    if nr_of_updates == 0 { return HttpResponse::BadRequest().json(json!({"status": "Invalid Body Error"})); }

    let mut build_update_query = String::from("SET ");

    if updates_first_name {
        build_update_query += format!("FIRSTNAME = '{}', ", body.FIRSTNAME.clone().unwrap()).as_str();
    }
    if updates_last_name {
        build_update_query += format!("LASTNAME = '{}', ", body.LASTNAME.clone().unwrap()).as_str();
    }
    if updates_email {
        build_update_query += format!("EMAIL = '{}', ", body.EMAIL.clone().unwrap()).as_str()
    }
    if updates_phone {
        build_update_query += format!("PHONE = '{}', ", body.PHONE.clone().unwrap()).as_str();
    }

    // Remove excessive ', '
    build_update_query.truncate(build_update_query.len().saturating_sub(2));

    let result = format!("UPDATE CONTACTINFO {} WHERE ID = '{}'", build_update_query, ci_id);

    match sqlx::query(result.as_str()).execute(&data.db).await {
        Ok(_) => {
                                HttpResponse::Ok().json(
                                json!(
                                    {
                                        "status": "success",
                                        "result": json!({
                                            "ID" : ci_id,
                                            "FIRSTNAME": if updates_first_name { body.FIRSTNAME.clone().unwrap() }
                                                         else { String::from("") },
                                            "LASTNAME":  if updates_last_name { body.LASTNAME.clone().unwrap() }
                                                         else { String::from("") },
                                            "EMAIL":     if updates_email { body.EMAIL.clone().unwrap() }
                                                         else { String::from("") },
                                            "PHONE":     if updates_phone { body.PHONE.clone().unwrap() }
                                                         else { String::from("") }
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

