use crate::model::contestresult::*;
use actix_web::{post, get, patch, web, HttpResponse, Responder};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::MySqlPool;
use uuid::Uuid;
use crate::api::general::{update_table_handler, FieldWithValue};
use crate::api::metric::create_metric;
use crate::model::metric::CreateMetric;

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct UpdateWrapper{ pub unit: String, pub metric_id: Option<String> }
#[patch("/contestresults/{id}")]
pub async fn contestresults_patch_handler(path: web::Path<String>,
                                          body: web::Json<UpdateContestResult>,
                                          db: web::Data<MySqlPool>) ->impl Responder {
    let ctr_id = path.into_inner();
    let ctr_query =
        sqlx::query_as!(ContestResult, "SELECT * FROM CONTESTRESULT WHERE ID = ?", ctr_id.clone())
            .fetch_one(db.as_ref())
            .await;
    if ctr_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Contestresult error",
        "message": ctr_query.err().unwrap().to_string()
    })); };

    let unit_query = sqlx::query_as!(UpdateWrapper,
        r#"SELECT UNIT as unit, METRIC_ID as metric_id FROM CONTESTRESULT as ctr
                                            JOIN CONTEST as ct ON ct.ID = ctr.CONTEST_ID
                                            JOIN C_TEMPLATE as ct_t ON ct_t.ID = ct.C_TEMPLATE_ID
                                            WHERE ctr.ID = ?
                                     "#, ctr_id).fetch_one(db.as_ref()).await;
    if unit_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Contestresult error",
        "message": unit_query.err().unwrap().to_string()
    })); };
    let update_info = unit_query.unwrap();
    if update_info.metric_id.is_none() {
        let new_metric = CreateMetric {
            TIME: body.time.clone(),
            TIMEUNIT: body.time_unit.clone(),
            LENGTH: body.length.clone(),
            LENGTHUNIT: body.length_unit.clone(),
            WEIGHT: body.weight.clone(),
            WEIGHTUNIT: body.weight_unit.clone(),
            AMOUNT: body.amount.clone()
        };
        let new_metric = create_metric(new_metric, &db).await;
        if new_metric.is_err() { return HttpResponse::InternalServerError().json(json!({
            "status": "New metric error",
            "message": new_metric.err().unwrap().to_string()
        })); };

        return HttpResponse::Ok().json(json!({
            "status": "success",
            "metric_id": serde_json::to_value(new_metric).unwrap()
        }));
    }

    let field = match update_info.unit.to_lowercase().as_str() {
        "m" => { if body.length.is_none() { return HttpResponse::BadRequest().json(json!({
                                                    "status": "This contest measures length",
                                                    })); };
                FieldWithValue{ name: "LENGTH", value: body.length.unwrap().to_string() }
        },
        "kg" => { if body.weight.is_none() { return HttpResponse::BadRequest().json(json!({
                                                    "status": "This contest measures weight",
                                                    })); };
            FieldWithValue{ name: "WEIGHT", value: body.weight.unwrap().to_string() }
        },
        "s" => { if body.time.is_none() { return HttpResponse::BadRequest().json(json!({
                                                    "status": "This contest measures time",
                                                    })); };
            FieldWithValue{ name: "TIME", value: body.time.unwrap().to_string() }
        },
        "amount" => { if body.amount.is_none() { return HttpResponse::BadRequest().json(json!({
                                                    "status": "This contest measures amounts",
                                                    })); };
            FieldWithValue{ name: "AMOUNT", value: body.amount.unwrap().to_string() }
        },
        _ => { return HttpResponse::InternalServerError().json(json!({ "status": "Unknown unit" })); }
    };

    let updated_fields = update_table_handler("METRIC",
                                             vec![field],
                                             format!("ID = \"{}\"", update_info.metric_id.unwrap()),
                                             db.as_ref()).await;
    if updated_fields.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Update Metric error",
    })); };
    let updated_fields = updated_fields.unwrap();
    if updated_fields.len() != 1 { return HttpResponse::InternalServerError().json(json!({
        "status": "Update Metric error 2",
    })); };

    HttpResponse::Ok().json(json!({
        "status": "success",
        "updated_fields": serde_json::to_value(updated_fields).unwrap(),
    }))
}
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
