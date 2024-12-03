use crate::model::contestresult::*;
use crate::model::contest::*;
use crate::{model, AppState};
use actix_web::{get, post, patch, web, HttpResponse, Responder};
use env_logger::builder;
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::mysql::{MySqlQueryResult, MySqlRow};
use sqlx::Row;
use uuid::{Uuid};
use crate::api::metric::{create_metric, to_metric};
use crate::model::metric::{CreateMetric, LengthUnit, Metric, TimeUnit, WeightUnit};

#[get("/contestresults")]
pub async fn get_contest_results_handler(data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query(format!("SELECT * FROM CONTESTRESULT").as_str())
        .map(|row : MySqlRow| ContestResult {
            ID : row.get::<String, _>("ID"),
            CONTEST_ID : row.get::<String, _>("CONTEST_ID"),
            PERSON_ID : row.get::<String, _>("PERSON_ID"),
            METRIC_ID : row.get::<String, _>("METRIC_ID"),
        }
        )
        .fetch_all(&data.db).await;


    match result {
        Ok(values) => {
            let contest_response = values.into_iter().map(|result| {
                json!({
                    "ID": result.ID,
                    "CONTEST_ID": result.CONTEST_ID,
                    "PERSON_ID": result.PERSON_ID,
                    "METRIC_ID": result.METRIC_ID,
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

#[get("/contests/{id}/contestresults")]
pub async fn contests_get_results_handler(path : web::Path<String>, data: web::Data<AppState>) -> impl Responder {
    let result = sqlx::query(format!("SELECT * FROM CONTESTRESULT WHERE ID = {}", path.into_inner()).as_str())
        .map(|row : MySqlRow| ContestResult {
                                ID : row.get::<String, _>("ID"),
                                CONTEST_ID : row.get::<String, _>("CONTEST_ID"),
                                PERSON_ID : row.get::<String, _>("PERSON_ID"),
                                METRIC_ID : row.get::<String, _>("METRIC_ID"),
                         }
                )
        .fetch_all(&data.db).await;


    match result {
        Ok(values) => {
            let contest_response = values.into_iter().map(|result| {
                json!({
                    "ID": result.ID,
                    "CONTEST_ID": result.CONTEST_ID,
                    "PERSON_ID": result.PERSON_ID,
                    "METRIC_ID": result.METRIC_ID,
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

#[post("/contestresults")]
pub async fn contestresult_create_handler(body: web::Json<CreateContestResult>, data: web::Data<AppState>) -> impl Responder {

    let metric_for_creation = to_metric(&body);

    let db_metric = create_metric(metric_for_creation, &data).await;

    if db_metric.is_none() { return HttpResponse::InternalServerError().json(json!({"status" : "Internal Error"})); }

    let result_id = Uuid::new_v4();

    let cr_query = sqlx::query(
        "INSERT INTO CONTESTRESULT (ID, CONTEST_ID, PERSON_ID, METRIC_ID) VALUES (?, ?, ?, ?)")
        .bind(result_id.to_string())
        .bind(body.CONTEST_ID.clone())
        .bind(body.PERSON_ID.clone())
        .bind(db_metric.as_ref().unwrap().ID.clone())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string());
    if let Err(e) = cr_query {
        return HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": "Failed to create contest with error: ".to_owned() + &e.to_string(),
        }))
    }

    HttpResponse::Created().json(json!({
        "status": "success",
        "message": "ContactInfo created successfully!",
        "data": json!({
            "ID": result_id.to_string(),
            "CONTEST_ID": body.CONTEST_ID,
            "PERSON_ID": body.PERSON_ID,
            "METRIC_ID": db_metric.unwrap().ID,
        })
    }))
}

#[post("/contests/{id}/contestresults")]
pub async fn contest_create_handler(body: web::Json<CreateContest>, data:web::Data<AppState>) -> impl Responder {
    let contest_id: Uuid = Uuid::new_v4();

    let query = sqlx::query(
        "INSERT INTO CONTEST (ID, SPORTFEST_ID, DETAILS_ID, CONTESTRESULT_ID) VALUES (?, ?, ?, ?)")
        .bind(contest_id.to_string())
        .bind(body.SPORTFEST_ID.clone())
        .bind(body.DETAILS_ID.clone())
        .bind(body.CONTESTRESULT_ID.clone())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string());
    if let Err(e) = query {
        return HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": "Failed to create contest with error: ".to_owned() + &e.to_string(),
        }))
    }

    HttpResponse::Created().json(json!({
        "status": "success",
        "message": "ContactInfo created successfully!",
        "data": json!({
            "ID": contest_id.to_string(),
            "SPORTFEST_ID": body.SPORTFEST_ID,
            "DETAILS_ID": body.DETAILS_ID,
            "CONTESTRESULT_ID": body.CONTESTRESULT_ID,
        })
    }))
}
