use actix::Addr;
use crate::model::contest::*;
use actix_web::{get, patch, post, web, HttpMessage, HttpRequest, HttpResponse, Responder};
use actix_web::web::Data;
use actix_web_actors::ws::Message;
use serde_json::json;
use sqlx::{MySqlPool, Row};
use uuid::{Uuid};
use crate::api::websocket::{ClientActorMessage, Lobby};
use crate::model::contestresult::{ContestResult, BatchContestResults, ContestResultContestView, PatchContestResults};
use crate::model::metric::Metric;
use crate::model::person::{Participant, Person};

pub async fn get_contest(id: String, db: &web::Data<MySqlPool>) -> Result<Contest, String>
{
    sqlx::query_as!(Contest, "SELECT * FROM CONTEST WHERE ID = ?", id.clone())
        .fetch_one(db.as_ref())
        .await.map_err(|e| e.to_string())
}

pub struct AscDescWrapper{
    pub ascending: String,
}

#[get("/contests/{id}/contestresults")]
pub async fn contest_get_results_by_id_handler(path: web::Path<String>, db: web::Data<MySqlPool>)
                                               -> impl Responder {
    let contest_id = path.into_inner();
    let contest_res = get_contest(contest_id.clone(), &db).await;

    if contest_res.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Get contest error",
        "message": contest_res.unwrap_err().to_string()
    })); }

    let master_query = sqlx::query_as!(
        ContestResultContestView,
        r#" SELECT
            ct.ID AS ct_id,

            p.ID AS p_id,
            p.ROLE AS p_role,
            p.FIRSTNAME AS p_firstname,
            p.LASTNAME AS p_lastname,
            p.EMAIL AS p_email,
            p.PHONE AS p_phone,
            p.GRADE AS p_grade,
            p.BIRTH_YEAR AS p_birth_year,

            m.VALUE AS value,
            m.UNIT AS unit

            FROM CONTEST AS ct
                JOIN CONTESTRESULT as cr ON cr.CONTEST_ID = ct.ID
                JOIN PERSON as p ON p.ID = cr.PERSON_ID
                LEFT JOIN METRIC as m ON m.ID = cr.METRIC_ID
                WHERE ct.ID = ?
            "#,
        contest_id.clone()
    )
        .fetch_all(db.as_ref())
        .await;

    let ascend_descend_query =
        sqlx::query_as!(AscDescWrapper, r#"SELECT ct_t.EVALUATION as ascending
                                                FROM C_TEMPLATE as ct_t
                                                JOIN CONTEST as ct ON ct.C_TEMPLATE_ID = ct_t.ID
                                                WHERE ct.ID = ?
                                                "#, contest_id)
        .fetch_one(db.as_ref()).await;
    if ascend_descend_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Evaluation query error"
    })); };

    match master_query {
        Ok(result) => HttpResponse::Ok().json(json!({
            "status": "success",
            "ascending": ascend_descend_query.unwrap().ascending,
            "data": serde_json::to_value(&result).unwrap(),
        })),
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": e.to_string()
        }))
    }
}

struct PersonToResult {
    pub p_id: String,
    pub m_id: String,
    pub value: f64
}

#[patch("/contests/{id}/contestresults")]
pub async fn contests_patch_results(body: web::Json<PatchContestResults>,
                                    path: web::Path<String>,
                                    db: Data<MySqlPool>,
                                    socket: Data<Addr<Lobby>>
)
    -> impl Responder
{
    if body.results.is_empty() { return HttpResponse::BadRequest().json(json!({
        "status": "No results to update error",
        "message": "There were no results to update in the body"
    })); };
    let contest_id = path.into_inner();
    let unit = sqlx::query_as!(UnitWrapper,
        "SELECT ct_t.UNIT as unit FROM CONTEST as ct JOIN C_TEMPLATE as ct_t ON ct.C_TEMPLATE_ID = ct_t.ID WHERE ct.ID = ?",
        contest_id.clone())
        .fetch_one(db.as_ref())
        .await;

    if unit.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Find Contest Error",
        "message": unit.unwrap_err().to_string()
    })); };
    let unit = unit.unwrap();

    let mut person_to_result_query =
        String::from(r#"SELECT ctr.PERSON_ID as p_id,
                                  ctr.METRIC_ID as m_id
                           FROM CONTESTRESULT as ctr WHERE ctr.CONTEST_ID = ""#);
    person_to_result_query += contest_id.as_str();
    person_to_result_query += r#"" AND ctr.PERSON_ID IN (""#;
    for results in &body.results {
        person_to_result_query += results.p_id.as_str();
        person_to_result_query += "\",\"";
    }
    person_to_result_query.truncate(person_to_result_query.len().saturating_sub(2));
    person_to_result_query += ")";

    let person_to_result = sqlx::query(person_to_result_query.as_str()).fetch_all(db.as_ref()).await;
    if person_to_result.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Get Person to Result error",
        "message": person_to_result.unwrap_err().to_string()
    })); };
    let person_to_result = person_to_result.unwrap();
    if person_to_result.len() != body.results.len() { return HttpResponse::BadRequest().json(json!({
        "status": "Invalid person ids",
        "message": format!("Only {} out of {} ids are valid", person_to_result.len(), body.results.len()),
    })); };

    let mut updates_to_do = person_to_result.into_iter().map(|row|{
        let m_id = row.try_get("m_id");
        let m_id = if m_id.is_err() {String::from("")} else {m_id.unwrap()};
        PersonToResult {
            m_id,
            p_id: row.try_get("p_id").unwrap(),
            value: body.results.iter().find( |result|
                (*result).p_id == row.try_get::<String, _>("p_id").unwrap()).unwrap().value
        }}
        ).collect::<Vec<PersonToResult>>();

    let mut metrics_query = String::from("INSERT INTO METRIC (ID,VALUE,UNIT) VALUES ");
    let mut delete_query = String::from("DELETE FROM METRIC WHERE ID IN (");
    let mut new_m_to_p_ids = Vec::<(String,String)>::with_capacity(12);

    for result in &mut updates_to_do {
        let new_m_id = Uuid::new_v4().to_string();
        if result.m_id.is_empty() {
            result.m_id = new_m_id.clone();
            new_m_to_p_ids.push((new_m_id, result.p_id.clone()));
        };
        metrics_query += "(\"";
        metrics_query += result.m_id.as_str();
        metrics_query += "\",";
        let to_push = format!("{},\"{}\"),", result.value, unit.unit.clone());
        metrics_query += to_push.as_str();

        if !result.m_id.is_empty() {
            delete_query += "\"";
            delete_query += result.m_id.clone().as_str();
            delete_query += "\",";
        }
    }
    metrics_query.truncate(metrics_query.len().saturating_sub(1));
    metrics_query += ";";
    delete_query.truncate(delete_query.len().saturating_sub(1));
    delete_query += ");";
    let mut tx = db.begin().await.expect("Failed to begin transaction");

    let delete_query = sqlx::query(&delete_query).execute(&mut *tx).await;
    if delete_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Delete metrics error",
        "message": delete_query.unwrap_err().to_string()
    })); };

    let metrics_query = sqlx::query(&metrics_query).execute(&mut *tx).await;
    if metrics_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Update metrics error",
        "message": metrics_query.unwrap_err().to_string()
    })); };

    if !new_m_to_p_ids.is_empty() {
        let mut ctr_query = String::from("UPDATE CONTESTRESULT SET METRIC_ID = CASE ");
        for new_m_to_p_id in new_m_to_p_ids {
            ctr_query += "WHEN CONTEST_ID = \"";
            ctr_query += contest_id.as_str();
            ctr_query += "\" AND PERSON_ID = \"";
            ctr_query += new_m_to_p_id.1.as_str();
            ctr_query += "\" THEN \"";
            ctr_query += new_m_to_p_id.0.as_str();
            ctr_query += "\" ";

        }
        ctr_query += "ELSE METRIC_ID END;";

        let ctr_query = sqlx::query(&ctr_query).execute(&mut *tx).await;
        if ctr_query.is_err() {
            return HttpResponse::InternalServerError().json(json!({
            "status": "Update ctr query error",
            "message": ctr_query.unwrap_err().to_string()
        })); };
    }

    tx.commit().await.expect("Failed to commit transaction");

    let length = updates_to_do.len();
    let mut msg_to_send = String::from("");
    for update in updates_to_do {
        msg_to_send += format!("{{\"msg_type\": \"CR_UPDATE\", \"data\":{{\"contestant_id\":\"{}\",\"value\":{}}} }}", update.p_id, update.value).as_str();
    }

    socket.send(ClientActorMessage{
        id: Uuid::new_v4(),
        msg: msg_to_send,
        room_id: Uuid::parse_str(contest_id.as_str()).unwrap()
    }).await.expect("Socket error!");

    HttpResponse::Ok().json(json!({
        "status": "success",
        "updated_fields": length
    }))
}

#[post("/contests/{id}/contestresults")]
pub async fn contests_create_results(body: web::Json<BatchContestResults>,
                                        path: web::Path<String>,
                                        db: web::Data<MySqlPool>)
                                             -> impl Responder
{
    let contest_id = path.into_inner();
    let unit = sqlx::query_as!(UnitWrapper,
        "SELECT ct_t.UNIT as unit FROM CONTEST as ct JOIN C_TEMPLATE as ct_t ON ct.C_TEMPLATE_ID = ct_t.ID WHERE ct.ID = ?",
        contest_id.clone())
        .fetch_one(db.as_ref())
        .await;

    if unit.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Find Contest Error",
        "message": unit.unwrap_err().to_string()
    })); };
    let unit = unit.unwrap();

    let mut build_metrics_query =
        String::from("INSERT INTO METRIC (ID,VALUE,UNIT) VALUES ");

    let mut build_cr_query = String::from("INSERT INTO CONTESTRESULT (ID, PERSON_ID, CONTEST_ID, METRIC_ID) VALUES ");

    let mut metric_parameters: Vec<Metric> = Vec::new();
    let mut cr_parameters : Vec<(String, String, String, String)> = Vec::new();

    for info in &body.results
    {
        build_metrics_query += "(?, ?, ?),";
        let new_metric_id = Uuid::new_v4().to_string();
        metric_parameters.push(Metric {
            id: new_metric_id.clone(),
            value: info.value,
            unit: unit.unit.clone(),
        });
        build_cr_query += "(?, ?, ?, ?),";
        let new_cr_id = Uuid::new_v4().to_string();
        cr_parameters.push((
            new_cr_id.clone(),
            info.p_id.clone(),
            contest_id.clone(),
            new_metric_id.clone()
        ));
    }

    build_metrics_query.pop();
    build_cr_query.pop();

    let mut metrics_query_builder = sqlx::query(&build_metrics_query);
    for metric in &metric_parameters {
        metrics_query_builder = metrics_query_builder
                                .bind(metric.id.clone())
                                .bind(metric.value.clone())
                                .bind(metric.unit.clone());
    }

    let mut cr_query_builder = sqlx::query(&build_cr_query);
    for (cr_id, p_id, cont_id, m_id) in &cr_parameters {
        cr_query_builder = cr_query_builder.bind(cr_id).bind(p_id).bind(cont_id).bind(m_id);
    }

    let mut tx = db.begin().await.expect("Failed to begin transaction");
    let metrics_res = metrics_query_builder.execute(&mut *tx).await;
    let cr_res = cr_query_builder.execute(&mut *tx).await;

    if metrics_res.is_err() {return HttpResponse::InternalServerError().json(json!({
        "status": "Metrics Error",
        "message": metrics_res.unwrap_err().to_string()
    }))};

    match cr_res {
        Ok(_) => { tx.commit().await.expect("Failed to commit transaction");
                    HttpResponse::Ok().json(json!({
                        "status": "success",
                        "results": cr_parameters.len(),
                    }))
        },
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "ContestResult Error",
            "message": e.to_string()
        }))
    }
}

#[get("/contests/{id}")]
pub async fn contests_get_master_view_handler(path: web::Path<String>, db: web::Data<MySqlPool>)
                                              -> impl Responder {
    let contest_id = path.into_inner();

    let contest_res = get_contest(contest_id.clone(), &db).await;
    if contest_res.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Get Contest Error",
        "message": contest_res.unwrap_err().to_string()
    })); }

    let master_query = sqlx::query_as!(
        ContestMaster,
        r#"   SELECT
                ct.ID AS ct_id,
                sf.ID AS sf_id,

                sf.DETAILS_ID AS sf_details_id,
                sfd.START AS sf_details_start,
                sfd.END AS sf_details_end,

                ctd.ID AS ct_details_id,
                ctd.NAME AS ct_details_name,
                ctd.START AS ct_details_start,
                ctd.END AS ct_details_end,

                sfp.ID AS sf_cp_id,
                sfp.FIRSTNAME AS sf_cp_firstname,
                sfp.LASTNAME AS sf_cp_lastname,
                sfp.EMAIL AS sf_cp_email,
                sfp.PHONE AS sf_cp_phone,
                sfp.GRADE AS sf_cp_grade,
                sfp.BIRTH_YEAR AS sf_cp_birth_year,

                ctp.ID AS ct_cp_id,
                ctp.FIRSTNAME AS ct_cp_firstname,
                ctp.LASTNAME AS ct_cp_lastname,
                ctp.EMAIL AS ct_cp_email,
                ctp.PHONE AS ct_cp_phone,
                ctp.GRADE AS ct_cp_grade,
                ctp.BIRTH_YEAR AS ct_cp_birth_year,

                sfl.CITY AS sf_city,
                sfl.ZIPCODE AS sf_zipcode,
                sfl.STREET AS sf_street,
                sfl.STREETNUMBER AS sf_streetnumber,
                sfl.NAME AS sf_location_name,

                ctl.CITY AS ct_city,
                ctl.ZIPCODE AS ct_zipcode,
                ctl.STREET AS ct_street,
                ctl.STREETNUMBER AS ct_streetnumber,
                ctl.NAME AS ct_location_name,

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
                     LOCATION as sfl ON sfl.ID = sfd.LOCATION_ID
                     JOIN
                     LOCATION as ctl ON ctl.ID = ctd.LOCATION_ID
        "#,
        contest_res.as_ref().unwrap().SPORTFEST_ID.clone(),
        contest_id.clone(),
    )
        .fetch_one(db.as_ref())
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
pub async fn contests_get_handler(db: web::Data<MySqlPool>) -> impl Responder {
    let result = sqlx::query_as!(Contest, "SELECT * FROM CONTEST")
        .fetch_all(db.as_ref())
        .await;

    match result {
        Ok(details) => HttpResponse::Ok().json(json!({
                "status": "success",
                "results": details.len(),
                "data": serde_json::to_value(&details).unwrap(),
                }))
        ,
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Contests: {}", e),
            }))
        }
    }
}

#[get("/contests/{id}/participants")]
pub async fn contests_get_participants_handler(path: web::Path<String>, db: web::Data<MySqlPool>) -> impl Responder {
    let ct_id = path.into_inner();
    let participants = sqlx::query_as!(Participant,
        r#"SELECT p.ID as id,
                  p.FIRSTNAME as f_name,
                  p.LASTNAME as l_name,
                  p.EMAIL as email,
                  p.PHONE as phone,
                  p.GRADE as grade,
                  p.BIRTH_YEAR as birth_year,
                  p.ROLE as role,
                  p.GENDER as gender,
                  p.PICS as pics,
                  p.DISABILITIES as disabilities

                  FROM CONTEST as ct
                  JOIN CONTESTRESULT as ctr ON ct.ID = ctr.CONTEST_ID
                  JOIN PERSON as p ON p.ID = ctr.PERSON_ID
                  WHERE ct.ID = ?"#,
        ct_id.clone())
        .fetch_all(db.as_ref())
        .await;
    if participants.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Participants error",
        "message": participants.unwrap_err().to_string(),
    })); };
    let participants = participants.unwrap();

    HttpResponse::Ok().json(json!({
        "status": "success",
        "data": serde_json::to_value(participants).unwrap(),
    }))
}

#[get("/contests/participants/mycontests")]
pub async fn contests_participants_mycontests_handler(db: web::Data<MySqlPool>, req: HttpRequest) -> impl Responder {
    let container = req.extensions();
    let user = container.get::<Person>();
    if user.is_none() { return HttpResponse::InternalServerError().json(json!({
        "status": "User was none error",
        "message": "Should not happen..",
    })); };
    let user = user.unwrap();println!("User was valid");

    let result = sqlx::query_as!(ContestForJudge,
            "SELECT ct.ID as ct_id,
                    dt.NAME as ct_name,
                    dt.START as ct_start,
                    dt.END as ct_end,
                    lc.NAME as ct_location_name,
                    ct_ct.UNIT as ct_unit,
                    sf_dt.NAME as sf_name

                    FROM CONTEST as ct
                    JOIN CONTESTRESULT as ctr ON ctr.CONTEST_ID = ct.ID
                    JOIN DETAILS as dt ON dt.ID = ct.DETAILS_ID
                    JOIN LOCATION as lc ON dt.LOCATION_ID = lc.ID
                    JOIN SPORTFEST as sf ON ct.SPORTFEST_ID = sf.ID
                    JOIN DETAILS as sf_dt ON sf_dt.ID = sf.DETAILS_ID
                    JOIN C_TEMPLATE as ct_ct ON ct_ct.ID = ct.C_TEMPLATE_ID
                    WHERE ctr.PERSON_ID = ?",user.ID.clone())
        .fetch_all(db.as_ref())
        .await;

    match result {
        Ok(details) => HttpResponse::Ok().json(json!({
                "status": "success",
                "data": serde_json::to_value(details).unwrap(),
                }))
        ,
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Contests: {}", e),
            }))
        }
    }
}

#[get("/contests/judge/mycontests")]
pub async fn contests_judge_mycontests_handler(db: web::Data<MySqlPool>, req: HttpRequest) -> impl Responder {
    let container = req.extensions();
    let user = container.get::<Person>();
    if user.is_none() { return HttpResponse::InternalServerError().json(json!({
        "status": "User was none error",
        "message": "Should not happen..",
    })); };
    let user = user.unwrap();

    let result = sqlx::query_as!(ContestForJudge,
            "SELECT ct.ID as ct_id,
                    dt.NAME as ct_name,
                    dt.START as ct_start,
                    dt.END as ct_end,
                    lc.NAME as ct_location_name,
                    ct_ct.UNIT as ct_unit,
                    sf_dt.NAME as sf_name

                    FROM CONTEST as ct
                    JOIN DETAILS as dt ON dt.ID = ct.DETAILS_ID
                    JOIN LOCATION as lc ON dt.LOCATION_ID = lc.ID
                    JOIN SPORTFEST as sf ON ct.SPORTFEST_ID = sf.ID
                    JOIN DETAILS as sf_dt ON sf_dt.ID = sf.DETAILS_ID
                    JOIN C_TEMPLATE as ct_ct ON ct_ct.ID = ct.C_TEMPLATE_ID
                    WHERE dt.CONTACTPERSON_ID = ?",user.ID.clone())
        .fetch_all(db.as_ref())
        .await;

    match result {
        Ok(details) => HttpResponse::Ok().json(json!({
                "status": "success",
                "data": serde_json::to_value(details).unwrap(),
                }))
        ,
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch Contests: {}", e),
            }))
        }
    }
}

pub async fn create_contest(contest: CreateContest, db: &web::Data<MySqlPool>) -> Result<Contest, String> {
    let contest_id = Uuid::new_v4();
    let new_template_id = Uuid::new_v4();

    let template_query =
        sqlx::query(r#"INSERT INTO C_TEMPLATE (ID, NAME, DESCRIPTION, GRADERANGE, EVALUATION, UNIT)
                        VALUES (?, ?, ?, ?, ?, ?)
        "#)
            .bind(new_template_id.to_string())
            .bind(contest.ct_name.clone())
            .bind(contest.ct_description.clone())
            .bind(contest.ct_graderange.clone())
            .bind(contest.ct_evaluation.clone())
            .bind(contest.ct_unit.clone())
            .execute(db.as_ref())
            .await;

    if template_query.is_err() { return Err(template_query.unwrap_err().to_string() + " in template query"); }

    let contest_query = sqlx::query(
        "INSERT INTO CONTEST (ID, SPORTFEST_ID, DETAILS_ID, C_TEMPLATE_ID) VALUES (?, ?, ?, ?)")
        .bind(contest_id.to_string())
        .bind(contest.SPORTFEST_ID.clone())
        .bind(contest.DETAILS_ID.clone())
        .bind(new_template_id.to_string())
        .execute(db.as_ref())
        .await;

    match contest_query {
        Ok(_) => Ok(Contest {
            ID: contest_id.to_string(),
            SPORTFEST_ID: contest.SPORTFEST_ID.clone(),
            DETAILS_ID: contest.DETAILS_ID.clone(),
            C_TEMPLATE_ID: new_template_id.to_string()
        }),
        Err(e) => Err(e.to_string() + " in contest query")
    }
}

#[post("/contests")]
pub async fn contests_create_handler(body: web::Json<CreateContest>, db: web::Data<MySqlPool>)
                                    -> impl Responder {
    let query = create_contest(body.0, &db).await;
    match query {
        Ok(result) => HttpResponse::Created().json(json!({
                "status": "success",
                "data": serde_json::to_value(&result).unwrap(),
                }))
        ,
        Err(e) => HttpResponse::InternalServerError().json(json!({
                "status": "Contest Create Error",
                "message":  e
            }))
    }
}

#[post("/contests/{id}/participants")]
pub async fn contests_create_participants_handler(body: web::Json<CreateParticipantsForContest>,
                                                  db: web::Data<MySqlPool>,
                                                  path: web::Path<String>
)
-> impl Responder {
    let contest_id = path.into_inner();
    let contest_query = sqlx::query_as!(Contest, "SELECT * FROM CONTEST WHERE ID = ?", contest_id)
        .fetch_one(db.as_ref())
        .await;
    if contest_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Contest id error",
        "message": contest_query.unwrap_err().to_string()
    }))};

    if body.participant_ids.as_ref().is_none() && body.classes.as_ref().is_none() {
        return HttpResponse::BadRequest().json(json!({
            "status": "No participants or classes error",
            "message": "Classes and Participants can not both be none"
        }));
    };

    let mut participants_ids_to_insert: Vec<String> = vec![];

    if body.participant_ids.as_ref().is_some() {
        let participant_ids = body.participant_ids.clone().unwrap();
        if participant_ids.is_empty() {
            return HttpResponse::InternalServerError().json(json!({
            "status": "Participant in body error",
            "message": "You didn't send any participant ids."
        }))
        };

        let mut list_of_ids = String::from("(\"");
        for participant_id in &participant_ids {
            list_of_ids.push_str(participant_id.as_str());
            list_of_ids.push_str("\", \"");
        }
        list_of_ids = list_of_ids[..list_of_ids.len() - 3].to_string();
        list_of_ids.push_str(")");

        let mut query = String::from("SELECT ID FROM PERSON WHERE ID IN ");
        query.push_str(list_of_ids.as_str());
        let query = sqlx::query(query.as_str())
            .fetch_all(db.as_ref())
            .await;
        if query.is_err() {
            return HttpResponse::InternalServerError().json(json!({
            "status": "Person query Db error",
            "message": query.unwrap_err().to_string()
        }))
        };

        if query.unwrap().len() != participant_ids.len() {
            return HttpResponse::InternalServerError().json(json!({
            "status": "Ids not all valid error",
            "message":  "Not all ids were valid"
        }))
        };

        participants_ids_to_insert.extend(participant_ids.into_iter());
    };

    if body.classes.as_ref().is_some() {
        if body.classes.as_ref().unwrap().is_empty() {
            return HttpResponse::Ok().json(json!({
            "status": "No classes found error",
            "message": "The send classes array is empty"
        }))
        };
        let mut classes_query = String::from("SELECT * FROM PERSON WHERE GRADE IN (\"");
        for class in body.classes.as_ref().unwrap() {
            classes_query.push_str(class.as_str());
            classes_query.push_str("\", \"");
        }
        classes_query = classes_query[..classes_query.len() - 3].to_string();
        classes_query.push_str(")");
        println!("Final {}", classes_query);
        let classes_query_result = sqlx::query(classes_query.as_str())
            .fetch_all(db.as_ref())
            .await;
        if classes_query_result.is_err() {
            return HttpResponse::InternalServerError().json(json!({
            "status": "Contest result query error",
            "message": classes_query_result.unwrap_err().to_string()
        }))
        };

        let people_of_classes = classes_query_result.unwrap().into_iter().map(
            |row| row.try_get("ID").unwrap()).collect::<Vec<String>>();
        if people_of_classes.is_empty() {
            return HttpResponse::BadRequest().json(json!({
            "status": "Bad classes error",
            "message": "There are no people in the send classes"
        }))};

        participants_ids_to_insert.extend(people_of_classes.into_iter());
    }

    if participants_ids_to_insert.is_empty() {
        return HttpResponse::InternalServerError().json(json!({
            "status": "Bad participants or classes error",
            "message": "Something went wrong.."
        }));
    };

    let mut contest_result_query = String::from("INSERT INTO CONTESTRESULT (ID, PERSON_ID, CONTEST_ID, METRIC_ID) VALUES ");
    for participant_id in &participants_ids_to_insert {
        let new_id = Uuid::new_v4();
        contest_result_query.push_str("(\"");
        contest_result_query.push_str(new_id.to_string().as_str());
        contest_result_query.push_str("\", \"");
        contest_result_query.push_str(&participant_id);
        contest_result_query.push_str("\", \"");
        contest_result_query.push_str(&contest_id.clone());
        contest_result_query.push_str("\", NULL), ");
    }
    contest_result_query = contest_result_query[..contest_result_query.len() - 2].to_string();
    match sqlx::query(contest_result_query.as_str()).execute(db.as_ref()).await {
        Ok(_) => HttpResponse::Ok().json(json!({
            "status": "Success",
            "added_persons": participants_ids_to_insert.len(),
        })),
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "Insert contest result error",
            "message": e.to_string()
        }))
    }
}

#[get("/contests/{contest_id}/participants/{participant_id}")]
pub async fn contests_check_participant_handler(path: web::Path<(String,String)>, db: web::Data<MySqlPool>) -> impl Responder {
    let (ct_id, p_id) = path.into_inner();

    let query =
        sqlx::query_as!(ContestResult, "SELECT * FROM CONTESTRESULT WHERE CONTEST_ID = ? AND PERSON_ID = ?",
        ct_id.clone(), p_id.clone()).fetch_all(db.as_ref()).await;
    if query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Contest result query error",
        "message": "Something went wrong, should not happen.."
    })); };
    let query = query.unwrap();
    if query.len() != 1 { return HttpResponse::BadRequest().json(json!({
        "status": "Not a Participant error",
    })); };

    HttpResponse::Ok().json(json!({
        "status": "success",
        "is_participant": true,
    }))
}

