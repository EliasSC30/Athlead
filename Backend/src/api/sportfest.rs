use crate::model::sportfest::*;
use crate::{AppState};
use actix_web::{get, post, patch, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};
use crate::api::details::create_details;
use crate::api::location::create_location;
use crate::model::sportfest::CreateContestForFest;
use crate::model::details::{CreateDetails};
use crate::model::location::CreateLocation;

#[get("/sportfests")]
pub async fn sportfests_list_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(
        Sportfest,
        "SELECT * FROM SPORTFEST"
    )
        .fetch_all(&data.db)
        .await;

    match result {
        Ok(sportfests) => {
            let sportfest_response = sportfests.into_iter().map(|sportfest| {
                json!({
                    "id": sportfest.ID,
                    "details_id": sportfest.DETAILS_ID,
                })
            }).collect::<Vec<serde_json::Value>>();

            HttpResponse::Ok().json(json!({
                "status": "success",
                "results": sportfest_response.len(),
                "data": sportfest_response,
            }))
        }
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch sportfests: {}", e),
            }))
        }
    }
}


#[get("/sportfests/{id}")]
pub async fn sportfests_get_masterview_handler(
    data: web::Data<AppState>,
    path: web::Path<String>
) -> impl Responder {
    let sportfest_id = path.into_inner();

    let details_id_query =
        sqlx::query_as!(
            Sportfest,
            "SELECT * FROM SPORTFEST WHERE ID = ?",
            sportfest_id.clone()).fetch_one(&data.db).await;

    if details_id_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
        "message": details_id_query.unwrap_err().to_string(),
    }))}

    let result = sqlx::query_as!(
            SportfestMaster,
            r#"SELECT
                SPORTFEST.ID AS sportfest_id,

                DETAILS.ID AS details_id,
                DETAILS.START AS details_start,
                DETAILS.END AS details_end,

                LOCATION.ID AS location_id,
                LOCATION.NAME AS location_name,
                LOCATION.CITY AS location_city,
                LOCATION.ZIPCODE AS location_zipcode,
                LOCATION.STREET AS location_street,
                LOCATION.STREETNUMBER AS location_street_number,

                PERSON.ID AS person_id,
                PERSON.ROLE as person_role,

                CONTACTINFO.ID AS cp_id,
                CONTACTINFO.FIRSTNAME AS cp_firstname,
                CONTACTINFO.LASTNAME AS cp_lastname,
                CONTACTINFO.EMAIL AS cp_email,
                CONTACTINFO.PHONE AS cp_phone,
                CONTACTINFO.GRADE AS cp_grade,
                CONTACTINFO.BIRTH_YEAR AS cp_birth_year

                   FROM
                    SPORTFEST JOIN
                     DETAILS ON DETAILS.ID = ?
                     JOIN
                     LOCATION ON DETAILS.LOCATION_ID = LOCATION.ID
                     JOIN
                     PERSON ON PERSON.ID = DETAILS.CONTACTPERSON_ID
                     JOIN
                     CONTACTINFO ON CONTACTINFO.ID = PERSON.CONTACTINFO_ID"#,
            details_id_query.unwrap().DETAILS_ID.clone()
        )
        .fetch_one(&data.db)
        .await;

    match result {
        Ok(values) => {
            HttpResponse::Ok().json(json!({
                "status": "success",
                "data": serde_json::to_value(values).unwrap(),
            }))
        }
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Sportfests: {}", e),
            }))
        }
    }
}

#[post("/sportfests")]
pub async fn sportfests_create_handler(body: web::Json<CreateSportfest>, data: web::Data<AppState>) -> impl Responder {
    let new_sportfest_id: Uuid = Uuid::new_v4();

    let location_for_create = CreateLocation {
        CITY: body.city.clone(),
        ZIPCODE: body.zip_code.clone(),
        STREET: body.street.clone(),
        STREETNUMBER: body.streetnumber.clone(),
        NAME: body.location_name.clone(),
    };
    let create_location = create_location(&location_for_create, &data).await;
    if create_location.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
        "message": create_location.unwrap_err().to_string(),
    }))};

    let details_for_create = CreateDetails {
        LOCATION_ID: create_location.unwrap().ID.clone(),
        CONTACTPERSON_ID: body.CONTACTPERSON_ID.clone(),
        NAME: body.fest_name.clone(),
        START: body.fest_start.clone(),
        END: body.fest_end.clone(),
    };

    let create_details = create_details(&details_for_create, &data).await;
    if create_details.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
        "message": create_details.unwrap_err()
    }))}

    let sf_query = sqlx::query(
        "INSERT INTO SPORTFEST (ID, DETAILS_ID) VALUES (?, ?)")
        .bind(new_sportfest_id.to_string())
        .bind(create_details.as_ref().clone().unwrap().ID.to_string())
        .execute(&data.db)
        .await;

    match sf_query {
        Ok(_) => HttpResponse::Ok().json(json!({
            "status": "success",
            "data": json!({
                "ID": new_sportfest_id.to_string(),
                "DETAILS_ID": create_details.unwrap().ID,
            }),
        })),
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": format!("Failed to insert SPORTFEST: {}", e),
        }))
    }

}

#[patch("/sportfests/{id}")]
pub async fn sportfests_update_handler(body: web::Json<UpdateSportfest>,
                                       data: web::Data<AppState>,
                                       path: web::Path<String>)
    -> impl Responder
{
    let sportfest_id = path.into_inner();

    let updates_details = body.DETAILS_ID.is_some();

    let nr_of_updates : u8 =
        [updates_details as u8].iter().sum();
    println!("Updates details: {}", nr_of_updates);
    if nr_of_updates == 0 { return HttpResponse::BadRequest().json(json!({"status": "Invalid Body Error"})); }

    let mut build_update_query = String::from("SET ");

    if updates_details {
        build_update_query += format!("DETAILS_ID = '{}', ", body.DETAILS_ID.clone().unwrap()).as_str();
    }

    // Remove excessive ', '
    build_update_query.truncate(build_update_query.len().saturating_sub(2));

    let result = format!("UPDATE SPORTFEST {} WHERE ID = '{}'", build_update_query, sportfest_id);

    match sqlx::query(result.as_str()).execute(&data.db).await {
        Ok(_) => {
            HttpResponse::Ok().json(
                json!(
                                {
                                    "status": "success",
                                    "result": json!({
                                        "ID" : sportfest_id,
                                        "DETAILS_ID":     if updates_details { body.DETAILS_ID.clone().unwrap() }
                                                          else { String::from("") },
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

#[get("/sportfests/{sf_id}/contests")]
pub async fn get_contest_of_sf_handler(path: web::Path<String>, data: web::Data<AppState>)
    -> impl Responder {
    let sf_id = path.into_inner();

    let sf_query = sqlx::query_as!(
        Sportfest,
        "SELECT * FROM SPORTFEST WHERE ID = ?",
        sf_id.clone()
    )
        .fetch_one(&data.db)
        .await;

    if sf_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
        "message": sf_query.unwrap_err().to_string(),
    }))};

   // let contest_query = sqlx::query_as!("");
    HttpResponse::Ok().json(json!(sf_query.unwrap()))
}

#[post("/sportfests/{id}/contests")]
pub async fn create_contest_for_sf_handler(body: web::Json<CreateContestForFest>,
                                    data: web::Data<AppState>,
                                    path :web::Path<String>
) -> impl Responder {
    let sf_id = path.into_inner();

    let query = sqlx::query_as!(
        Sportfest,
        "SELECT * FROM SPORTFEST WHERE ID = ?",
        sf_id)
        .fetch_one(&data.db)
        .await;

    if let Err(e) = query {
        return HttpResponse::InternalServerError().json(json!({
            "status": "Find Sportfest Error",
            "message": e.to_string(),
        }))
    }

    let detail_values = CreateDetails::from(body.LOCATION_ID.clone(),
                                                        body.CONTACTPERSON_ID.clone(),
                                                        body.NAME.clone(),
                                                        body.START.clone(),
                                                        body.END.clone());

    let details_res = create_details(&detail_values, &data).await;

    if details_res.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
        "message": details_res.unwrap_err().to_string()
    }))};

    let contest_id = Uuid::new_v4();
    let contest_query = sqlx::query(
            "INSERT INTO CONTEST (ID, SPORTFEST_ID, DETAILS_ID, C_TEMPLATE_ID) VALUES (?, ?, ?, ?)"
    )
        .bind(contest_id.clone().to_string())
        .bind(&sf_id.clone())
        .bind(&details_res.as_ref().clone().unwrap().ID)
        .bind(&body.C_TEMPLATE_ID.clone())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string());
    match contest_query {
        Ok(_) => {
            HttpResponse::Ok().json(json!({
                "status": "success",
                "data": json!({
                    "ID": contest_id.to_string(),
                    "SPORTFEST_ID": sf_id,
                    "DETAILS_ID": details_res.unwrap().ID,
                    "C_TEMPLATE_ID": body.C_TEMPLATE_ID,
                })
            }))
        },
        Err(e) => HttpResponse::InternalServerError().json(json!({
        "status": "Create Contest Error",
        "message": e.to_string()
    }))
    }

}
