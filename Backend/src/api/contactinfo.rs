use crate::model::contactinfo::*;
use crate::AppState;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};

#[get("/contactinfo")]
pub async fn contactinfo_list_handler(data: web::Data<AppState>) -> impl Responder {

    let details: Vec<ContactInfo> = sqlx::query_as!(
        ContactInfo,
        r#"SELECT * FROM CONTACTINFO"#)
        .fetch_all(&data.db)
        .await
        .map_err(|e| {
            return HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": "Failed to fetch ContactInfo, with error: ".to_owned() + &e.to_string(),
            }))
        })
        .unwrap();

    /*
        pub ID: String,
    pub FIRSTNAME: String,
    pub LASTNAME: String,
    pub EMAIL: String,
    pub PHONE: String,
     */
    let contactinfo_response = details.into_iter().map(|contactinfo| {
        json!({
            "ID": contactinfo.ID,
            "FIRSTNAME": contactinfo.FIRSTNAME,
            "LASTNAME": contactinfo.LASTNAME,
            "EMAIL": contactinfo.EMAIL,
            "PHONE": contactinfo.PHONE,
        })
    }).collect::<Vec<serde_json::Value>>();

    return HttpResponse::Ok().json(json!({
        "status": "success",
        "results": contactinfo_response.len(),
        "data": contactinfo_response,
    }));
}

#[post("/contactinfos")]
pub async fn contactinfo_create_handler(body: web::Json<CreateContactInfo>, data:web::Data<AppState>) -> impl Responder {
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

    return HttpResponse::Created().json(json!({
        "status": "success",
        "message": "ContactInfo created successfully!",
        "data": json!({
            "ID": new_details_id.to_string(),
            "FIRSTNAME": body.FIRSTNAME,
            "LASTNAME": body.LASTNAME,
            "EMAIL": body.EMAIL,
            "PHONE": body.PHONE
        })
    }));
}