use crate::model::contest::*;
use crate::AppState;
use actix_web::{get, post, patch, web, HttpResponse, Responder};
use env_logger::builder;
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::mysql::MySqlQueryResult;
use uuid::{Uuid};
use crate::model::contactinfo::CreateContactInfo;


#[get("/contests/{id}")]
pub async fn get_contest_handler(path: web::Path<String>, data: web::Data<AppState>)
    -> impl Responder {
    let contest_id = path.into_inner();

    let contest_query = sqlx::query_as!(Contest, "SELECT * FROM CONTEST WHERE ID = ?", contest_id.clone())
        .fetch_one(&data.db)
        .await;
    if contest_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Internal server error",
        "message": contest_query.err().unwrap().to_string(),
    })); }


    let master_query = sqlx::query_as!(
        ContestMaster,
        r#"
            SELECT
                ct.ID AS ct_id,
                sf.ID AS sf_id,

                sf.DETAILS_ID AS sf_details_id,
                sfd.START AS sf_details_start,
                sfd.END AS sf_details_end,

                ctd.ID as ct_details_id,
                ctd.START AS ct_details_start,
                ctd.END AS ct_details_end,

                sfp_ci.ID AS sf_cp_id,
                sfp_ci.FIRSTNAME AS sf_cp_firstname,
                sfp_ci.LASTNAME AS sf_cp_lastname,
                sfp_ci.EMAIL AS sf_cp_email,
                sfp_ci.PHONE AS sf_cp_phone,
                sfp_ci.GRADE AS sf_cp_grade,
                sfp_ci.BIRTH_YEAR AS sf_cp_birth_year,

                ctp_ci.ID AS ct_cp_id,
                ctp_ci.FIRSTNAME AS ct_cp_firstname,
                ctp_ci.LASTNAME AS ct_cp_lastname,
                ctp_ci.EMAIL AS ct_cp_email,
                ctp_ci.PHONE AS ct_cp_phone,
                ctp_ci.GRADE AS ct_cp_grade,
                ctp_ci.BIRTH_YEAR AS ct_cp_birth_year,

                sfl.CITY AS sf_city,
                sfL.ZIPCODE AS sf_zipcode,
                sfl.STREET AS sf_street,
                sfl.STREETNUMBER AS sf_streetnumber,
                sfl.NAME AS sf_name,

                ctl.CITY AS ct_city,
                ctl.ZIPCODE AS ct_zipcode,
                ctl.STREET AS ct_street,
                ctl.STREETNUMBER AS ct_streetnumber,
                ctl.NAME AS ct_name,

                ct.CONTESTRESULT_ID AS CONTESTRESULT_ID,
                ct.C_TEMPLATE_ID AS C_TEMPLATE_ID

                   FROM
                    CONTEST AS ct
                     JOIN
                     SPORTFEST AS sf ON sf.ID = ? AND ct.ID = ?
                     JOIN
                     DETAILS as sfd ON sfd.ID = sf.DETAILS_ID
                     JOIN
                     DETAILS as ctd ON ctd.ID = ct.DETAILS_ID
                     JOIN
                     PERSON as sfp ON sfp.ID = sfd.CONTACTPERSON_ID
                     JOIN
                     PERSON as ctp ON ctp.ID = ctd.CONTACTPERSON_ID
                     JOIN
                     CONTACTINFO as sfp_ci ON sfp_ci.ID = sfp.CONTACTINFO_ID
                     JOIN
                     CONTACTINFO as ctp_ci ON ctp_ci.ID = ctp.CONTACTINFO_ID
                     JOIN
                     LOCATION as sfl ON sfl.ID = sfd.LOCATION_ID
                     JOIN
                     LOCATION as ctl ON ctl.ID = ctd.LOCATION_ID
        "#,
        contest_query.as_ref().unwrap().SPORTFEST_ID.clone(),
        contest_id.clone(),
    )
        .fetch_one(&data.db)
        .await;

    match master_query {
        Ok(values) => HttpResponse::Ok().json(json!({
            "status": "success",
            "data": serde_json::to_value(&values).unwrap(),
        })),
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "Internal server error",
            "message": e.to_string()
        }))
    }
}

#[get("/contests")]
pub async fn contests_get_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query_as!(Contest, "SELECT * FROM CONTEST")
        .fetch_all(&data.db)
        .await;

    match result {
        Ok(details) => {
            let contest_response = details.into_iter().map(|contest_info| {
                json!({
                    "ID": contest_info.ID,
                    "SPORTFEST_ID": contest_info.SPORTFEST_ID,
                    "DETAILS_ID": contest_info.DETAILS_ID,
                    "CONTESTRESULT_ID": contest_info.CONTESTRESULT_ID,
                })
            }).collect::<Vec<serde_json::Value>>();

            HttpResponse::Ok().json(json!({
                "status": "success",
                "results": contest_response.len(),
                "data": contest_response,
            }))
        }
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Contests: {}", e),
            }))
        }
    }
}

pub async fn create_contest(contest: CreateContest, data: &web::Data<AppState>) -> Result<MySqlQueryResult, String> {
    let contest_id: Uuid = Uuid::new_v4();

    sqlx::query(
        "INSERT INTO CONTEST (ID, SPORTFEST_ID, DETAILS_ID, CONTESTRESULT_ID) VALUES (?, ?, ?, ?)")
        .bind(contest_id.to_string())
        .bind(contest.SPORTFEST_ID.clone())
        .bind(contest.DETAILS_ID.clone())
        .bind(contest.CONTESTRESULT_ID.clone())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string())
}

#[post("/contests")]
pub async fn contest_create_handler(body: web::Json<CreateContest>, data:web::Data<AppState>) -> impl Responder {
    let query = create_contest(body.0, &data).await;
    match query {
        Ok(result) => {
            HttpResponse::Created().json(json!({
                "status": "success",
                "message": "ContactInfo created successfully!",
                "data": ""
                }))
        },
        Err(e) => { HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": "Failed to create contest with error: ".to_owned() + &e.to_string()
            }))
        }
    }
}

