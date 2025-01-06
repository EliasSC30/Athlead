use actix::Addr;
use crate::model::contestresult::*;
use actix_web::{get, patch, web, HttpResponse, Responder};
use actix_web_actors::ws;
use actix_web_actors::ws::Message;
use serde::{Deserialize, Serialize};
use serde_json::json;
use sqlx::MySqlPool;
use uuid::Uuid;
use crate::api::general::{update_table_handler, FieldWithValue};
use crate::api::metric::create_metric;
use crate::api::websocket::{ClientActorMessage, Lobby, WsMessage};
use crate::model::metric::CreateMetric;

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
#[allow(non_snake_case)]
pub struct UpdateWrapper{ pub unit: String, pub metric_id: Option<String>, pub ct_id: String }
#[patch("/contestresults/{id}")]
pub async fn contestresults_patch_handler(path: web::Path<String>,
                                          body: web::Json<UpdateContestResult>,
                                          db: web::Data<MySqlPool>,
                                          socket: web::Data<Addr<Lobby>>
) ->impl Responder {
    let ctr_id = path.into_inner();println!("ctr_id: {}", ctr_id);
    let ctr_query =
        sqlx::query_as!(ContestResult, "SELECT * FROM CONTESTRESULT WHERE ID = ?", ctr_id.clone())
            .fetch_one(db.as_ref())
            .await;
    if ctr_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Contestresult error",
        "message": ctr_query.err().unwrap().to_string()
    })); };

    let unit_query = sqlx::query_as!(UpdateWrapper,
        r#"SELECT ct_t.UNIT as unit, ctr.METRIC_ID as metric_id, ct.ID as ct_id
                                            FROM CONTESTRESULT as ctr
                                            JOIN CONTEST as ct ON ct.ID = ctr.CONTEST_ID
                                            JOIN C_TEMPLATE as ct_t ON ct_t.ID = ct.C_TEMPLATE_ID
                                            WHERE ctr.ID = ?"#
                                            , ctr_id).fetch_one(db.as_ref()).await;
    if unit_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Contestresult error",
        "message": unit_query.err().unwrap().to_string()
    })); };
    let update_info = unit_query.unwrap();
    if update_info.metric_id.is_none() {
        let new_metric = CreateMetric {
            value: body.value.clone(),
            unit: update_info.unit.clone()
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

    let field = FieldWithValue{ name: "VALUE", value: body.value.to_string()};
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

    socket.send(ClientActorMessage{
        id: Uuid::new_v4(),
        msg: String::from("Elias ist der Beste"),
        room_id: Uuid::parse_str(update_info.ct_id.as_str()).unwrap()
    }).await;

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
