use crate::model::contest::*;
use crate::AppState;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use uuid::{Uuid};
use crate::model::contestresult::{ContestResultContestView, CreateContestResultContestView};

pub async fn get_contest(id: String, db: &web::Data<AppState>) -> Result<Contest, String>
{
    sqlx::query_as!(Contest, "SELECT * FROM CONTEST WHERE ID = ?", id.clone())
        .fetch_one(&db.db)
        .await.map_err(|e| e.to_string())
}

#[get("/contests/{id}/contestresults")]
pub async fn contest_get_results_by_id_handler(path: web::Path<String>, data: web::Data<AppState>)
                                               -> impl Responder {
    let contest_id = path.into_inner();
    let contest_res = get_contest(contest_id.clone(), &data).await;

    if contest_res.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
        "message": contest_res.unwrap_err().to_string()
    })); }

    let master_query = sqlx::query_as!(
        ContestResultContestView,
        r#" SELECT
            ct.ID AS CONTEST_ID,

            p.ID AS p_id,
            p.ROLE AS p_role,
            p_ci.FIRSTNAME AS p_firstname,
            p_ci.LASTNAME AS p_lastname,
            p_ci.EMAIL AS p_email,
            p_ci.PHONE AS p_phone,
            p_ci.GRADE AS p_grade,
            p_ci.BIRTH_YEAR AS p_birth_year,

            m.TIME AS time,
            m.TIMEUNIT AS time_unit,
            m.LENGTH AS length,
            m.LENGTHUNIT AS length_unit,
            m.WEIGHT AS weight,
            m.WEIGHTUNIT AS weight_unit,
            m.amount AS amount
            FROM CONTEST AS ct
                JOIN CONTESTRESULT as cr ON cr.CONTEST_ID = ?
                JOIN METRIC as m ON m.ID = cr.METRIC_ID
                JOIN PERSON as p ON p.ID = cr.PERSON_ID
                JOIN CONTACTINFO as p_ci ON p_ci.ID = p.CONTACTINFO_ID
            "#,
        contest_id.clone()
    )
        .fetch_all(&data.db)
        .await;

    match master_query {
        Ok(result) => HttpResponse::Ok().json(json!({
            "status": "success",
            "results": result.len(),
            "data": serde_json::to_value(&result).unwrap(),
        })),
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": e.to_string()
        }))
    }
}

#[post("/contests/{id}/contestresults")]
pub async fn contests_create_results(body: web::Json<Vec<CreateContestResultContestView>>,
                                        path: web::Path<String>,
                                        data: web::Data<AppState>)
                                             -> impl Responder
{
    let contest_id = path.into_inner();
    let find_contest_query = get_contest(contest_id.clone(), &data).await;

    if find_contest_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Find Contest Error",
        "message": find_contest_query.unwrap_err().to_string()
    })); }

    let mut build_metrics_query =
        String::from("INSERT INTO METRIC (ID, TIME, TIMEUNIT, LENGTH, LENGTHUNIT, WEIGHT, WEIGHTUNIT, AMOUNT) VALUES ");

    let mut build_cr_query = String::from("INSERT INTO CONTESTRESULT (ID, PERSON_ID, CONTEST_ID, METRIC_ID) VALUES ");

    let mut metric_parameters: Vec<(String, Option<f64>, String, Option<f64>, String, Option<f64>, String, Option<f64>)> = Vec::new();
    let mut cr_parameters : Vec<(String, String, String, String)> = Vec::new();

    for info in &body.0
    {
        build_metrics_query += "(?, ?, ?, ?, ?, ?, ?, ?),";
        let new_metric_id = Uuid::new_v4().to_string();
        metric_parameters.push((
                new_metric_id.clone(),
                info.time,
                info.time_unit.clone().or(Some("s".to_string())).unwrap(),
                info.length,
                info.length_unit.clone().or(Some("m".to_string())).unwrap(),
                info.weight,
                info.weight_unit.clone().or(Some("kg".to_string())).unwrap(),
                info.amount
            ));
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

    println!("build_cr_query: {:?}", build_cr_query.clone());
    println!("params: {:?}", cr_parameters.clone());

    let mut metrics_query_builder = sqlx::query(&build_metrics_query);
    for (id, t, tu, l, lu, w, wu, a) in &metric_parameters {
        metrics_query_builder = metrics_query_builder.bind(id).bind(t).bind(tu).bind(l).bind(lu).bind(w).bind(wu).bind(a);
    }

    let mut cr_query_builder = sqlx::query(&build_cr_query);
    for (cr_id, p_id, cont_id, m_id) in &cr_parameters {
        cr_query_builder = cr_query_builder.bind(cr_id).bind(p_id).bind(cont_id).bind(m_id);
    }

    let metrics_res = metrics_query_builder.execute(&data.db).await;
    let cr_res = cr_query_builder.execute(&data.db).await;

    if metrics_res.is_err() {return HttpResponse::InternalServerError().json(json!({
        "status": "Metrics Error",
        "message": metrics_res.unwrap_err().to_string()
    }))};

    match cr_res {
        Ok(_) => HttpResponse::Ok().json(json!({
            "status": "success",
            "results": cr_parameters.len(),
        })),
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "ContestResult Error",
            "message": e.to_string()
        }))
    }
}

#[get("/contests/{id}")]
pub async fn contests_get_master_view_handler(path: web::Path<String>, data: web::Data<AppState>)
                                              -> impl Responder {
    let contest_id = path.into_inner();

    let contest_res = get_contest(contest_id.clone(), &data).await;
    if contest_res.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
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
                     CONTACTINFO as sfp_ci ON sfp_ci.ID = sfp.CONTACTINFO_ID
                     JOIN
                     CONTACTINFO as ctp_ci ON ctp_ci.ID = ctp.CONTACTINFO_ID
                     JOIN
                     LOCATION as sfl ON sfl.ID = sfd.LOCATION_ID
                     JOIN
                     LOCATION as ctl ON ctl.ID = ctd.LOCATION_ID
        "#,
        contest_res.as_ref().unwrap().SPORTFEST_ID.clone(),
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

pub async fn create_contest(contest: CreateContest, data: &web::Data<AppState>) -> Result<Contest, String> {
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
            .execute(&data.db)
            .await;

    if template_query.is_err() { return Err(template_query.unwrap_err().to_string() + " in template query"); }

    let contest_query = sqlx::query(
        "INSERT INTO CONTEST (ID, SPORTFEST_ID, DETAILS_ID, C_TEMPLATE_ID) VALUES (?, ?, ?, ?)")
        .bind(contest_id.to_string())
        .bind(contest.SPORTFEST_ID.clone())
        .bind(contest.DETAILS_ID.clone())
        .bind(new_template_id.to_string())
        .execute(&data.db)
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
pub async fn contests_create_handler(body: web::Json<CreateContest>, data:web::Data<AppState>)
                                    -> impl Responder {
    let query = create_contest(body.0, &data).await;
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

