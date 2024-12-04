use crate::model::location::*;
use crate::AppState;
use actix_web::{get, post, patch, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};

#[get("/locations")]
pub async fn locations_list_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(
        Location,
        "SELECT * FROM LOCATION"
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
        "SELECT * FROM LOCATION WHERE ID = ?",
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

pub async fn create_location(loc: &CreateLocation, data: &web::Data<AppState>) -> Result<Location, String>
{
    let new_location_id: Uuid = Uuid::new_v4();
    let query = sqlx::query(
        "INSERT INTO LOCATION (ID, CITY, ZIPCODE, STREET, STREETNUMBER, NAME) VALUES (?, ?, ?, ?, ?, ?)",
    )
        .bind(new_location_id.to_string())
        .bind(loc.CITY.clone())
        .bind(loc.ZIPCODE.clone())
        .bind(loc.STREET.clone())
        .bind(loc.STREETNUMBER.clone())
        .bind(loc.NAME.clone())
        .execute(&data.db)
        .await;

    match query {
        Ok(_) => Ok(Location {
            ID: new_location_id.to_string(),
            CITY: loc.CITY.clone(),
            ZIPCODE: loc.ZIPCODE.clone(),
            STREET: loc.STREET.clone(),
            STREETNUMBER: loc.STREETNUMBER.clone(),
            NAME: loc.NAME.clone()
        }),
        Err(e) => Err(e.to_string())
    }

}

#[post("/locations")]
pub async fn locations_create_handler(body: web::Json<CreateLocation>, data:web::Data<AppState>) -> impl Responder {
    match create_location(&body.0, &data).await {

        Ok(location) => HttpResponse::Ok().json(json!({
            "status": "success",
            "data": serde_json::to_value(&location).unwrap()
        })),
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "Location Error",
            "message": e
        }))}
}

#[patch("/locations/{id}")]
pub async fn locations_update_handler(body: web::Json<UpdateLocation>,
                                      data:web::Data<AppState>,
                                      path: web::Path<String>)
                                      -> impl Responder {
    let location_id = path.into_inner();

    let updates_city = body.CITY.is_some();
    let updates_zip = body.ZIPCODE.is_some();
    let updates_street = body.STREET.is_some();
    let updates_street_nr = body.STREETNUMBER.is_some();
    let updates_name = body.NAME.is_some();


    let nr_of_updates : u8 =
        [updates_city as u8, updates_zip as u8, updates_street as u8, updates_street_nr as u8, updates_name as u8].iter().sum();
    if nr_of_updates == 0 { return HttpResponse::BadRequest().json(json!({"status": "Invalid Body Error"})); }

    let mut build_update_query = String::from("SET ");

    if updates_city {
        build_update_query += format!("CITY = '{}', ", body.CITY.clone().unwrap()).as_str();
    }
    if updates_zip {
        build_update_query += format!("ZIPCODE = '{}', ", body.ZIPCODE.clone().unwrap()).as_str();
    }
    if updates_street {
        build_update_query += format!("STREET = '{}', ", body.STREET.clone().unwrap()).as_str();
    }
    if updates_street_nr {
        build_update_query += format!("STREETNUMBER = '{}', ", body.STREETNUMBER.clone().unwrap()).as_str();
    }
    if updates_name {
        build_update_query += format!("NAME = '{}', ", body.NAME.clone().unwrap()).as_str()
    }

    // Remove excessive ', '
    build_update_query.truncate(build_update_query.len().saturating_sub(2));

    let result = format!("UPDATE LOCATION {} WHERE ID = '{}'", build_update_query, location_id);

    match sqlx::query(result.as_str()).execute(&data.db).await {
        Ok(_) => {
            HttpResponse::Ok().json(
                json!(
                                    {
                                        "status": "success",
                                        "result": json!({
                                            "ID" : location_id,
                                            "CITY":     if updates_city { body.CITY.clone().unwrap() }
                                                            else { String::from("") },
                                            "ZIPCODE":      if updates_zip { body.ZIPCODE.clone().unwrap() }
                                                            else { String::from("") },
                                            "STREET":       if updates_name { body.STREET.clone().unwrap() }
                                                            else { String::from("") },
                                            "STREETNUMBER": if updates_street { body.STREETNUMBER.clone().unwrap().to_string() }
                                                            else { String::from("") },
                                            "NAME":         if updates_name { body.NAME.clone().unwrap().to_string() }
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
