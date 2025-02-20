use crate::model::details::*;
use actix_web::{get, post, patch, web, HttpResponse, Responder};
use serde_json::json;
use sqlx::MySqlPool;
use uuid::{Uuid};

#[get("/details")]
pub async fn details_get_all_handler(db: web::Data<MySqlPool>) -> impl Responder {
    let query = sqlx::query_as!(
        Details,
        "SELECT * FROM DETAILS"
    )
        .fetch_all(db.as_ref())
        .await;

    match query {
        Ok(details) => HttpResponse::Ok().json(json!({
                "status": "success",
                "results": details.len(),
                "data": serde_json::to_value(&details).unwrap(),
            }))
        ,
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Details: {}", e),
            }))
        }
    }
}

#[get("/details/{id}")]
pub async fn details_get_by_id_handler(
    db: web::Data<MySqlPool>,
    path: web::Path<String>
) -> impl Responder {
    let details_id = path.into_inner();

    let result = sqlx::query_as!(
        Details,
        "SELECT * FROM DETAILS WHERE ID = ?",
        details_id
    )
        .fetch_one(db.as_ref())
        .await;

    match result {
        Ok(detail) => {
            HttpResponse::Ok().json(json!({
                "status": "success",
                "data": serde_json::to_value(&detail).unwrap()
            }))
        }
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": format!("Failed to fetch Details: {}", e),
        }))
    }
}

pub async fn create_details(details : &CreateDetails, db : &web::Data<MySqlPool>)
    -> Result<Details,String> {
    let new_details_id: Uuid = Uuid::new_v4();

    let query = sqlx::query(
        "INSERT INTO DETAILS (ID, LOCATION_ID, CONTACTPERSON_ID, NAME, START, END) VALUES (?, ?, ?, ?, ?, ?)")
        .bind(new_details_id.to_string())
        .bind(details.LOCATION_ID.to_string())
        .bind(details.CONTACTPERSON_ID.to_string())
        .bind(details.NAME.clone())
        .bind(details.START)
        .bind(details.END)
        .execute(db.as_ref())
        .await.map_err(|e: sqlx::Error| e.to_string());

    match query {
        Ok(_) => Ok(
            Details {
                ID: new_details_id.to_string(),
                LOCATION_ID: details.LOCATION_ID.clone(),
                CONTACTPERSON_ID: details.CONTACTPERSON_ID.clone(),
                NAME: details.NAME.clone(),
                START: details.START.clone(),
                END: details.END.clone()
            }),
        Err(e) => Err(e.to_string())
    }
}

#[post("/details")]
pub async fn details_create_handler(body: web::Json<CreateDetails>, data:web::Data<MySqlPool>) -> impl Responder {
    match create_details(&body.0, &data).await {
        Ok(values) => {
            HttpResponse::Ok().json(json!(
                                        {
                                            "status": "success",
                                            "result": serde_json::to_value(&values).unwrap(),
                                        }
            ))
        },
        Err(e) => HttpResponse::InternalServerError().json(json!({"status": e.to_string()}))
    }
}

pub async fn update_details(details_id : String,
                      update_details : UpdateDetails,
                      db: web::Data<MySqlPool>) -> impl Responder {
    let updates_location = update_details.LOCATION_ID.is_some();
    let updates_cp = update_details.CONTACTPERSON_ID.is_some();
    let updates_name = update_details.NAME.is_some();
    let updates_start = update_details.START.is_some();
    let updates_end = update_details.END.is_some();


    let nr_of_updates : u8 =
        [updates_location as u8, updates_cp as u8, updates_name as u8, updates_start as u8, updates_end as u8].iter().sum();
    if nr_of_updates == 0 { return HttpResponse::BadRequest().json(json!({"status": "Invalid Body Error"})); }

    let mut build_update_query = String::from("SET ");

    if updates_location {
        build_update_query += format!("LOCATION_ID = '{}', ", update_details.LOCATION_ID.clone().unwrap()).as_str();
    }
    if updates_cp {
        build_update_query += format!("CONTACTPERSON_ID = '{}', ", update_details.CONTACTPERSON_ID.clone().unwrap()).as_str();
    }
    if updates_name {
        build_update_query += format!("NAME = '{}', ", update_details.NAME.clone().unwrap()).as_str()
    }
    if updates_start {
        let mut valid_str = update_details.START.clone().unwrap().to_string();
        valid_str.truncate(valid_str.len().saturating_sub(4)); // Remove " UTC"
        build_update_query += format!("START = '{}', ", valid_str.as_str()).as_str();
    }
    if updates_end {
        let mut valid_str = update_details.END.clone().unwrap().to_string();
        valid_str.truncate(valid_str.len().saturating_sub(4)); // Remove " UTC"
        build_update_query += format!("END = '{}', ", valid_str.as_str()).as_str();
    }

    // Remove excessive ', '
    build_update_query.truncate(build_update_query.len().saturating_sub(2));

    let result = format!("UPDATE DETAILS {} WHERE ID = '{}'", build_update_query, details_id);

    match sqlx::query(result.as_str()).execute(db.as_ref()).await {
        Ok(_) => {
            HttpResponse::Ok().json(
                json!(
                                    {
                                        "status": "success",
                                        "result": json!({
                                            "ID" : details_id,
                                            "LOCATION":         if updates_location { update_details.LOCATION_ID.clone().unwrap() }
                                                                else { String::from("") },
                                            "CONTACTPERSON_ID": if updates_cp { update_details.CONTACTPERSON_ID.clone().unwrap() }
                                                                else { String::from("") },
                                            "NAME":             if updates_name { update_details.NAME.clone().unwrap() }
                                                                else { String::from("") },
                                            "START":            if updates_start { update_details.START.clone().unwrap().to_string() }
                                                                else { String::from("") },
                                            "END":              if updates_end { update_details.END.clone().unwrap().to_string() }
                                                                else { String::from("") }
                                        }),
                                    }))
        }
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

#[patch("/details/{id}")]
pub async fn details_update_handler(body: web::Json<UpdateDetails>,
                                   db: web::Data<MySqlPool>,
                                   path: web::Path<String>)
    -> impl Responder
{
    let details_id = path.into_inner();

    update_details(details_id, body.0, db).await
}

