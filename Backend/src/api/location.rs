use crate::model::location::*;
use crate::AppState;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{uuid, Uuid};

#[get("/locations")]
pub async fn locations_list_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(
        Location,
        r#"SELECT * FROM LOCATION"#
    )
        .fetch_all(&data.db)
        .await;

    match result {
        Ok(locations) => {
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

            HttpResponse::Ok().json(json!({
                "status": "success",
                "results": location_response.len(),
                "data": location_response,
            }))
        }
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch locations: {}", e),
            }))
        }
    }
}

#[get("/locations/{id}")]
pub async fn locations_get_handler(
    data: web::Data<AppState>,
    path: web::Path<String>
) -> impl Responder {
    let location_id = path.into_inner();

    let result = sqlx::query_as!(
        Location,
        r#"SELECT * FROM LOCATION WHERE ID = ?"#,
        location_id
    )
        .fetch_one(&data.db)
        .await;

    match result {
        Ok(location) => {
            HttpResponse::Ok().json(json!({
                "status": "success",
                "data": {
                    "ID": location.ID,
                    "CITY": location.CITY,
                    "ZIPCODE": location.ZIPCODE,
                    "STREET": location.STREET,
                    "STREETNUMBER": location.STREETNUMBER,
                    "NAME": location.NAME
                }
            }))
        }
        Err(e) => {
            if e.to_string().contains("no rows returned by a query that expected to return at least one row") {
                HttpResponse::NotFound().json(json!({
                    "status": "error",
                    "message": "Locations not found",
                }))
            } else {
                HttpResponse::InternalServerError().json(json!({
                    "status": "error",
                    "message": format!("Failed to fetch Locations: {}", e),
                }))
            }
        }
    }
}

#[post("/locations")]
pub async fn locations_create_handler(body: web::Json<CreateLocation>, data:web::Data<AppState>) -> impl Responder {
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