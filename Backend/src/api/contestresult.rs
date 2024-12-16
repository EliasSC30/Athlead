use crate::model::contestresult::*;
use actix_web::{post, get, web, HttpResponse, Responder};
use serde_json::json;
use sqlx::MySqlPool;
use uuid::Uuid;
use crate::api::metric::create_metric;
use crate::model::metric::CreateMetric;

#[get("/contestresults")]
pub async fn get_contest_results_handler(db: web::Data<MySqlPool>) -> impl Responder {
    let result = sqlx::query_as!(
        ContestResult,
        "SELECT * FROM CONTESTRESULT"
        )
        .fetch_all(db.as_ref()).await;


    match result {
        Ok(values) => HttpResponse::Ok().json(json!({
                "status": "success",
                "results": values.len(),
                "data": serde_json::to_value(values).unwrap(),
            }))
        ,
        Err(e) => HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Contests: {}", e),
            }))

    }
}

pub async fn create_contest_result(contest_id: &String, person_id: &String, metric_id: &String, db: &web::Data<MySqlPool>)
    -> Result<ContestResult, String> {
    let cr_id = Uuid::new_v4();

    let query = sqlx::query("INSERT INTO CONTESTRESULT (ID, PERSON_ID, CONTEST_ID, METRIC_ID) VALUES (?, ?, ?, ?)")
        .bind(cr_id.to_string())
        .bind(person_id.clone())
        .bind(contest_id.clone())
        .bind(metric_id.clone())
        .execute(db.as_ref())
        .await;
    match query {
        Ok(_) => Ok(ContestResult {
            ID: cr_id.to_string(),
            PERSON_ID: person_id.clone(),
            CONTEST_ID: contest_id.clone(),
            METRIC_ID: Some(metric_id.clone())
        }),
        Err(e) => Err(e.to_string())
    }
}

#[post("/contestresults")]
pub async fn contestresult_create_handler(body: web::Json<CreateContestResult>,
                                          db: web::Data<MySqlPool>)
                                          -> impl Responder
{
    let metric_for_create = CreateMetric {
        TIME: body.time.clone(),
        TIMEUNIT: body.time_unit.clone(),
        LENGTH: body.length.clone(),
        LENGTHUNIT: body.length_unit.clone(),
        WEIGHT: body.weight.clone(),
        WEIGHTUNIT: body.weight_unit.clone(),
        AMOUNT: body.amount.clone(),
    };

    let metric_query = create_metric(metric_for_create, &db).await;
    if metric_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
        "message": metric_query.err().unwrap().to_string()
    }))};

    match create_contest_result(&body.CONTEST_ID, &body.PERSON_ID, &metric_query.unwrap().ID, &db).await {
        Ok(result) => HttpResponse::Ok().json(json!({
            "status": "success",
            "data": serde_json::to_value(result).unwrap()
        })),
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": format!("Failed to create Contests: {}", e),
        }))
    }
}
