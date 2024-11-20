use crate::model::location::*;
use crate::AppState;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{uuid, Uuid};

#[get("/locations")]
pub async fn location_list_handler(data: web::Data<AppState>) -> impl Responder {

    let locations: Vec<Location> = sqlx::query_as!(
        Location,
        r#"SELECT * FROM LOCATION"#)
        .fetch_all(&data.db)
        .await
        .map_err(|e| {
            return HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": "Failed to fetch location, with error: ".to_owned() + &e.to_string(),
            }))
        })
        .unwrap();
    let location_response = locations.into_iter().map(|location| {
        json!({
            "ID": location.ID,
            "CITY": location.CITY,
            "ZIPCODE": location.ZIPCODE,
            "STREET": location.STREET,
            "STREETNUMBER": location.STREETNUMBER,
            "NAME": location.NAME
        })
    }).collect::<Vec<serde_json::Value>>();

    return HttpResponse::Ok().json(json!({
        "status": "success",
        "results": location_response.len(),
        "data": location_response,
    }));
}


#[post("/location")]
pub async fn location_create_handler(body: web::Json<CreateLocation>, data:web::Data<AppState>) -> impl Responder {
    let new_location_id: Uuid = Uuid::new_v4();
    let query = sqlx::query(
        r#"INSERT INTO LOCATION (ID, CITY, ZIPCODE, STREET, STREETNUMBER, NAME) VALUES (?, ?, ?, ?, ?, ?)"#)
        .bind(new_location_id.to_string())
        .bind(body.CITY.clone())
        .bind(body.ZIPCODE.clone())
        .bind(body.STREET.clone())
        .bind(body.STREETNUMBER.clone())
        .bind(body.NAME.clone())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string());

    if let Err(e) = query {
        return HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": "Failed to create location, with error: ".to_owned() + &e.to_string(),
        }))
    }


    return HttpResponse::Created().json(json!({
        "status": "success",
        "message": "Location created successfully!",
        "data": json!({
            "ID": new_location_id.to_string(),
            "CITY": body.CITY,
            "ZIPCODE": body.ZIPCODE,
            "STREET": body.STREET,
            "STREETNUMBER": body.STREETNUMBER,
            "NAME": body.NAME
        })
    }));
}