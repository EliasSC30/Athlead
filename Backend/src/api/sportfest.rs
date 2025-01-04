use std::cmp::Reverse;
use std::collections::HashMap;
use crate::model::sportfest::*;
use actix_web::{get, post, patch, web, HttpResponse, Responder, HttpRequest, HttpMessage};
use serde_json::json;
use sqlx::{MySqlPool, Row};
use uuid::{Uuid};
use crate::api::details::create_details;
use crate::api::general::{update_table_handler, FieldWithValue};
use crate::api::location::create_location;
use crate::model::contest::{Contest, ContestEvaluation};
use crate::model::contestresult::ContestResult;
use crate::model::sportfest::CreateContestForFest;
use crate::model::details::{CreateDetails};
use crate::model::location::{CreateLocation, Location};
use crate::model::person::Person;

#[patch("/sportfests/{id}")]
pub async fn sportfests_patch_handler(path: web::Path<String>, db: web::Data<MySqlPool>, updates: web::Json<UpdateSportfest>) -> impl Responder {
    let sf_id = path.into_inner();
    let sf_query =
        sqlx::query_as!(Sportfest,"SELECT * FROM SPORTFEST WHERE ID = ?", sf_id.clone())
        .fetch_one(db.as_ref()).await;
    if sf_query.is_err() { return HttpResponse::BadRequest().json(json!({
        "status": "Invalid Sportfest Id",
        "message": sf_query.unwrap_err().to_string()
    })); };

    let mut updated_fields: Vec<FieldWithValue> = vec![];

    let mut fields_to_update = Vec::<FieldWithValue>::with_capacity(5);
    if updates.location_id.is_some() { fields_to_update.push(FieldWithValue{name: "LOCATION_ID", value: updates.location_id.clone().unwrap()}); };
    if updates.contact_person_id.is_some() { fields_to_update.push(FieldWithValue{name: "CONTACTPERSON_ID", value: updates.contact_person_id.clone().unwrap()}); };
    if updates.fest_name.is_some() { fields_to_update.push(FieldWithValue{name: "NAME", value: updates.fest_name.clone().unwrap()}); };
    if updates.fest_start.is_some() { fields_to_update.push(FieldWithValue{name: "START", value: updates.fest_start.clone().unwrap().to_string()}); };
    if updates.fest_end.is_some() { fields_to_update.push(FieldWithValue{name: "END", value: updates.fest_end.clone().unwrap().to_string()}); };

    if fields_to_update.is_empty() { return HttpResponse::Ok().json(json!({
        "status": "success",
        "updated_fields": serde_json::to_value(updated_fields).unwrap()
    })); };

    let mut updated_details_fields = update_table_handler("DETAILS",
                                              fields_to_update,
                                              format!("ID = \"{}\"", sf_query.unwrap().DETAILS_ID),
                                              db.as_ref()).await;
    if updated_details_fields.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Update Details error",
        "message": updated_details_fields.err().unwrap()
    })); };
    updated_fields.extend(updated_details_fields.unwrap());

    HttpResponse::Ok().json(json!({
        "status": "success",
        "updated_fields": serde_json::to_value(updated_fields).unwrap()
    }))
}

#[get("/sportfests")]
pub async fn sportfests_list_handler(db: web::Data<MySqlPool>, req: HttpRequest) -> impl Responder {
    let container = req.extensions();
    let user = container.get::<Person>();
    if user.is_none() { return HttpResponse::InternalServerError().json(json!({
        "status": "User was none error",
        "message": "Should not happen..",
    }))};
    let user = user.unwrap();

    let sf_query = sqlx::query_as!(
        Sportfest,
        "SELECT * FROM SPORTFEST"
    )
        .fetch_all(db.as_ref())
        .await;
    if sf_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Internal server error"
    })); }
    let sfs = sf_query.unwrap();

    let mut sf_contents: Vec<Result<SportfestMasterWithArrays, String>> = vec![];
    for sf in sfs {
        let sf_id = sf.ID.to_string();
        let user_cloned = user.clone();
        sf_contents.push(get_sf_masterview(sf_id, user_cloned, &db).await);
    }

    if sf_contents.iter().any(|res| res.is_err()) {
        return HttpResponse::InternalServerError().json(json!({"status": "Couldn't get all"}));};
    let sf_contents = sf_contents.into_iter().map(|res| res.unwrap())
        .collect::<Vec<SportfestMasterWithArrays>>();

    HttpResponse::Ok().json(json!({
        "status": "success",
        "data": serde_json::to_value(sf_contents).unwrap()
    }))
}


pub async fn get_sf_masterview(sf_id: String, user: Person, db: &web::Data<MySqlPool>)
    -> Result<SportfestMasterWithArrays, String> {
    let details_id_query =
        sqlx::query_as!(Sportfest,"SELECT * FROM SPORTFEST WHERE ID = ?",sf_id.clone())
            .fetch_one(db.as_ref())
            .await;

    if details_id_query.is_err() { return Err(details_id_query.unwrap_err().to_string()); };

    let contests_query = sqlx::query_as!(Contest,
        "SELECT * FROM CONTEST WHERE SPORTFEST_ID = ?",
        sf_id)
        .fetch_all(db.as_ref())
        .await;
    if contests_query.is_err() { return Err(contests_query.unwrap_err().to_string()); };

    let participating_classes: Vec<String> = if contests_query.as_ref().unwrap().len() == 0 { vec![] } else {
        let mut ct_query = String::from("SELECT * FROM CONTESTRESULT WHERE CONTEST_ID IN (\"");
        for contest in contests_query.unwrap() {
            ct_query.push_str(&contest.ID.as_str());
            ct_query.push_str("\", \"");
        }
        // Remove excessive " OR "
        ct_query = ct_query[..ct_query.len()-3].to_string();
        ct_query.push_str(")");

        let ct_results_query = sqlx::query(ct_query.as_str()).fetch_all(db.as_ref()).await;
        if ct_results_query.is_err() { return Err(ct_results_query.unwrap_err().to_string()); };
        let ct_results = ct_results_query.unwrap();

        if ct_results.len() > 0 {
            let ct_results = ct_results.into_iter().map(|row| {
                ContestResult {
                    ID: row.try_get("ID").unwrap(),
                    PERSON_ID: row.try_get("PERSON_ID").unwrap(),
                    CONTEST_ID: row.try_get("CONTEST_ID").unwrap(),
                    METRIC_ID: row.try_get("METRIC_ID").unwrap(),
                }
            }).collect::<Vec<ContestResult>>();

            let mut person_query = String::from("SELECT GRADE FROM PERSON WHERE ID IN (\"");
            for ct_result in ct_results {
                person_query.push_str(&ct_result.PERSON_ID.as_str());
                person_query.push_str("\", \"");
            }
            // Remove excessive ", "
            person_query = person_query[..person_query.len() - 3].to_string();
            person_query.push_str(") GROUP BY GRADE");

            let person_query = sqlx::query(person_query.as_str()).fetch_all(db.as_ref()).await;
            if person_query.is_err() { return Err(person_query.unwrap_err().to_string()); };
            let person_query = person_query.unwrap();
            if person_query.is_empty() { return Err(String::from("Invalid values in DB")); }

            person_query.into_iter().map(|row|{
                let content = row.try_get("GRADE");
                if content.is_err() { return String::from("No class"); };
                content.unwrap()
            }).collect()
        } else { vec![] }
    };


    // all participant classes with flag if user in it, user is in it-flag, all contests with flag if user in it
    let result = sqlx::query_as!(
            SportfestMaster,
            r#"SELECT
                SPORTFEST.ID AS sportfest_id,

                DETAILS.ID AS details_id,
                DETAILS.NAME AS details_name,
                DETAILS.START AS details_start,
                DETAILS.END AS details_end,

                LOCATION.ID AS location_id,
                LOCATION.NAME AS location_name,
                LOCATION.CITY AS location_city,
                LOCATION.ZIPCODE AS location_zipcode,
                LOCATION.STREET AS location_street,
                LOCATION.STREETNUMBER AS location_street_number,

                PERSON.ID AS cp_id,
                PERSON.ROLE as cp_role,
                PERSON.FIRSTNAME AS cp_firstname,
                PERSON.LASTNAME AS cp_lastname,
                PERSON.EMAIL AS cp_email,
                PERSON.PHONE AS cp_phone,
                PERSON.GRADE AS cp_grade,
                PERSON.BIRTH_YEAR AS cp_birth_year

                   FROM
                    SPORTFEST JOIN
                     DETAILS ON DETAILS.ID = ?
                     JOIN
                     LOCATION ON DETAILS.LOCATION_ID = LOCATION.ID
                     JOIN
                     PERSON ON PERSON.ID = DETAILS.CONTACTPERSON_ID"#,
            details_id_query.unwrap().DETAILS_ID.clone()
        )
        .fetch_one(db.as_ref())
        .await;
    if result.is_err() { return Err(result.unwrap_err().to_string()); };

    let contest_query = sqlx::query_as!(Contest, "SELECT * FROM CONTEST WHERE SPORTFEST_ID = ?", sf_id.clone())
        .fetch_all(db.as_ref())
        .await;
    if contest_query.is_err() { return Err(contest_query.unwrap_err().to_string()); };
    let contests_of_sf = contest_query.unwrap();

    let user_class = user.GRADE.clone().unwrap_or("".to_string());
    let participating_classes_with_flags = participating_classes.into_iter().map(|grade|{
        PartClassesWithInItFlag {
            in_it: grade == user_class,
            grade
        }
    }).collect::<Vec<PartClassesWithInItFlag>>();

    let contests_with_flags: Vec<ContestWithPartFlag> = if contests_of_sf.len() > 0 {
        let mut contestresult_query = String::from("SELECT * FROM CONTESTRESULT WHERE CONTEST_ID IN (\"");
        for contest in &contests_of_sf {
            contestresult_query.push_str(&contest.ID.as_str());
            contestresult_query.push_str("\", \"");
        }
        contestresult_query = contestresult_query[..contestresult_query.len()-3].to_string();
        contestresult_query.push_str(")");

        let contestresult_query = sqlx::query(contestresult_query.as_str())
            .fetch_all(db.as_ref())
            .await;
        if contestresult_query.is_err() { return Err(contestresult_query.unwrap_err().to_string()); };

        let all_participating_people = contestresult_query.unwrap().into_iter().map(|row|{
            (row.try_get("PERSON_ID").unwrap(), row.try_get("CONTEST_ID").unwrap())
        }).collect::<Vec<(String,String)>>();
        let contests_of_user = all_participating_people.iter().filter(|(p_id, ct_id)|{
            *p_id == user.ID.clone()
        }).map(|(p_id,ct_id)| ct_id.clone()).collect::<Vec<String>>();

        contests_of_sf.into_iter().map(|ct| {
            ContestWithPartFlag {
                participates: contests_of_user.iter().any( |user_ct| *user_ct == ct.ID),
                contest_id: ct.ID
            }
        }).collect::<Vec<ContestWithPartFlag>>()
    } else { vec![] };

    let sf = result.unwrap();
    let ret = SportfestMasterWithArrays{
        sportfest_id : sf.sportfest_id,

        details_id : sf.details_id,
        details_name: sf.details_name,
        details_start : sf.details_start,
        details_end : sf.details_end,

        location_id : sf.location_id,
        location_name : sf.location_name,
        location_city : sf.location_city,
        location_zipcode : sf.location_zipcode,
        location_street : sf.location_street,
        location_street_number : sf.location_street_number,

        cp_id : sf.cp_id,
        cp_role : sf.cp_role,
        cp_firstname : sf.cp_firstname,
        cp_lastname : sf.cp_lastname,
        cp_email : sf.cp_email,
        cp_phone : sf.cp_phone,
        cp_grade : sf.cp_grade,
        cp_birth_year : sf.cp_birth_year,

        part_cls_wf: participating_classes_with_flags,
        cts_wf: contests_with_flags
    };
    Ok(ret)
}

#[get("/sportfests/{id}")]
pub async fn sportfests_get_masterview_handler(
    db: web::Data<MySqlPool>,
    path: web::Path<String>,
    req: HttpRequest
) -> impl Responder {
    let sf_id = path.into_inner();

    let container = req.extensions();
    let user = container.get::<Person>();
    if user.is_none() { return HttpResponse::InternalServerError().json(json!({
        "status": "User was none error",
        "message": "Should not happen..",
    }))};

    match get_sf_masterview(sf_id, (*user.unwrap()).clone(), &db).await {
        Ok(Sf_wa) => {
            HttpResponse::Ok().json(json!({
                "status": "success",
                "data": serde_json::to_value(Sf_wa).unwrap()
            }))
        },
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "Get SF Masterview error",
                "message": e,
            }))
        }
    }
}

#[post("/sportfests")]
pub async fn sportfests_create_handler(body: web::Json<CreateSportfest>, db: web::Data<MySqlPool>) -> impl Responder {
    let new_sportfest_id: Uuid = Uuid::new_v4();

    let location_for_create = CreateLocation {
        CITY: body.city.clone(),
        ZIPCODE: body.zip_code.clone(),
        STREET: body.street.clone(),
        STREETNUMBER: body.streetnumber.clone(),
        NAME: body.location_name.clone(),
    };
    let create_location = create_location(&location_for_create, &db).await;
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

    let create_details = create_details(&details_for_create, &db).await;
    if create_details.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
        "message": create_details.unwrap_err()
    }))}

    let sf_query = sqlx::query(
        "INSERT INTO SPORTFEST (ID, DETAILS_ID) VALUES (?, ?)")
        .bind(new_sportfest_id.to_string())
        .bind(create_details.as_ref().clone().unwrap().ID.to_string())
        .execute(db.as_ref())
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

#[post("/sportfests_with_location")]
pub async fn sportfests_create_with_location_handler(body: web::Json<CreateSportfestWithLocation>, db: web::Data<MySqlPool>)
    -> impl Responder {
    let new_sportfest_id: Uuid = Uuid::new_v4();


    let details_for_create = CreateDetails {
        LOCATION_ID: body.location_id.clone(),
        CONTACTPERSON_ID: body.CONTACTPERSON_ID.clone(),
        NAME: body.fest_name.clone(),
        START: body.fest_start.clone(),
        END: body.fest_end.clone(),
    };

    let create_details = create_details(&details_for_create, &db).await;
    if create_details.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
        "message": create_details.unwrap_err()
    }))}

    let sf_query = sqlx::query(
        "INSERT INTO SPORTFEST (ID, DETAILS_ID) VALUES (?, ?)")
        .bind(new_sportfest_id.to_string())
        .bind(create_details.as_ref().clone().unwrap().ID.to_string())
        .execute(db.as_ref())
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
            "status": "Insert Sportfest Error",
            "message": format!("Failed to insert SPORTFEST: {}", e),
        }))
    }
}

pub fn placing_points(placing: usize) -> u32
{
    match placing {
        0 => 25,
        1 => 18,
        2 => 15,
        3 => 12,
        4 => 10,
        5 => 8,
        6 => 6,
        7 => 4,
        8 => 2,
        9 => 1,
        _ => 0
    }
}

pub fn evaluate_contest(mut contest: Vec<ContestEvaluation>) -> Vec<PersonWithResult>
{
    let asc = contest.get(0).unwrap().evaluation == "ASCENDING";
    contest.sort_by(|lhs,rhs| {
        if asc { lhs.m_value.partial_cmp(&rhs.m_value).unwrap() }
        else { rhs.m_value.partial_cmp(&lhs.m_value).unwrap() }
    });

    let mut points_for_contestants = Vec::<PersonWithResult>::with_capacity(contest.len());
    for index in 0..contest.len() {
        let info = contest.get(index).unwrap();
        points_for_contestants.push(
            PersonWithResult {
                p_f_name: info.p_f_name.clone(),
                p_l_name: info.p_l_name.clone(),
                p_email: info.p_email.clone(),
                p_phone: info.p_phone.clone(),
                p_grade: info.p_grade.clone(),
                p_birth_year: info.p_birth_year.clone(),
                p_role: info.p_role.clone(),
                p_gender: info.p_gender.clone(),
                p_pics: info.p_pics.clone(),
                value: info.m_value,
                unit: info.m_unit.clone(),
                points: placing_points(index)});
    }

    points_for_contestants
}

pub fn person_result_to_person_point(p: PersonWithResult) -> PersonWithPoint {
    PersonWithPoint{
        p_f_name: p.p_f_name.clone(),
        p_l_name: p.p_l_name.clone(),
        p_email: p.p_email.clone(),
        p_phone: p.p_phone.clone(),
        p_grade: p.p_grade.clone(),
        p_birth_year: p.p_birth_year.clone(),
        p_role: p.p_role.clone(),
        p_gender: p.p_gender.clone(),
        p_pics: p.p_pics.clone(),
        points: p.points,
    }
}

#[get("/sportfests/{id}/results")]
pub async fn sportfests_get_results_by_id_handler(db: web::Data<MySqlPool>,
                                                  path: web::Path<String>
)
    -> impl Responder {
    let sf_id = path.into_inner();

    let contests =
        sqlx::query_as!(ContestEvaluation, r#"SELECT
                                    ct.ID as ct_id,
                                    ct.DETAILS_ID as ct_details_id,
                                    ct_d.NAME as contest_name,
                                    ct_t.EVALUATION as evaluation,
                                    ct_t.UNIT as unit,

                                    p.FIRSTNAME as p_f_name,
                                    p.LASTNAME as p_l_name,
                                    p.EMAIL as p_email,
                                    p.PHONE as p_phone,
                                    p.GRADE as p_grade,
                                    p.BIRTH_YEAR as p_birth_year,
                                    p.ROLE as p_role,
                                    p.GENDER as p_gender,
                                    p.PICS as p_pics,

                                    m.VALUE as m_value,
                                    m.UNIT as m_unit

                                    FROM CONTEST as ct
                                    JOIN C_TEMPLATE as ct_t ON ct.C_TEMPLATE_ID = ct_t.ID
                                    JOIN CONTESTRESULT as ct_res ON ct.ID = ct_res.CONTEST_ID
                                    JOIN METRIC as m ON ct_res.METRIC_ID = m.ID
                                    JOIN PERSON as p ON p.ID = ct_res.PERSON_ID
                                    JOIN DETAILS as ct_d ON ct_d.ID = ct.DETAILS_ID
                                    WHERE SPORTFEST_ID = ?
                                    ORDER BY ct.ID ASC
                                    "#
            ,sf_id)
            .fetch_all(db.as_ref()).await;
    if contests.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Get Contest Error",
        "message": contests.unwrap_err().to_string()
    })); };
    let contests = contests.unwrap();
    let mut index = 0;
    let mut all_contests: Vec<Vec<ContestEvaluation>> = vec![];
    while index < contests.len() {
        let mut contest: Vec<ContestEvaluation> = vec![];
        let cur_contest_id = contests.get(index).unwrap().ct_id.clone();
        while index < contests.len() && cur_contest_id == contests.get(index).unwrap().ct_id {
            contest.push(contests.get(index).unwrap().clone());
            index += 1;
        }
        if !contest.is_empty() { all_contests.push(contest); };
        index += 1;
    }

    let all_results =
        all_contests.into_iter().map(|ct_eval|{
            let unit = ct_eval.get(0).unwrap().unit.clone();
            let id = ct_eval.get(0).unwrap().ct_id.clone();
            ContestWithResults{ id, unit, results: evaluate_contest(ct_eval)}
        })
            .collect::<Vec<ContestWithResults>>();

    let mut total_points = HashMap::<String, PersonWithPoint>::new();
    all_results.clone().into_iter().for_each(|ct|{
        ct.results.into_iter().for_each(|result| {
            let prev_entry = total_points.get(&result.p_email);
            if prev_entry.is_some() {
                let prev_entry = prev_entry.unwrap();
                let updated = PersonWithPoint {
                    p_f_name: prev_entry.p_f_name.clone(),
                    p_l_name: prev_entry.p_l_name.clone(),
                    p_email: prev_entry.p_email.clone(),
                    p_phone: prev_entry.p_phone.clone(),
                    p_grade: prev_entry.p_grade.clone(),
                    p_birth_year: prev_entry.p_birth_year.clone(),
                    p_role: prev_entry.p_role.clone(),
                    p_gender: prev_entry.p_gender.clone(),
                    p_pics: prev_entry.p_pics.clone(),
                    points: prev_entry.points + result.points};
                total_points.insert(result.p_email.clone(), updated);
            } else {
                total_points.insert(result.p_email.clone(), person_result_to_person_point(result));
            }
        });
    });

    let mut total_points =
        total_points.values().into_iter().map(|p| (*p).clone() ).collect::<Vec<PersonWithPoint>>();
    total_points.sort_by_key(|p_w_p| Reverse(p_w_p.points));


    HttpResponse::Ok().json(json!({
        "status": "success",
        "contests": serde_json::to_value(all_results).unwrap(),
        "contestants_totals": serde_json::to_value(total_points).unwrap()
    }))
}

#[get("/sportfests/{sf_id}/contests")]
pub async fn get_contest_of_sf_handler(path: web::Path<String>, db: web::Data<MySqlPool>)
    -> impl Responder {
    let sf_id = path.into_inner();

    let sf_query = sqlx::query_as!(
        Sportfest,
        "SELECT * FROM SPORTFEST WHERE ID = ?",
        sf_id.clone()
    )
        .fetch_one(db.as_ref())
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
                                    db: web::Data<MySqlPool>,
                                    path :web::Path<String>
) -> impl Responder {
    let sf_id = path.into_inner();

    let query = sqlx::query_as!(
        Sportfest,
        "SELECT * FROM SPORTFEST WHERE ID = ?",
        sf_id)
        .fetch_one(db.as_ref())
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

    let details_res = create_details(&detail_values, &db).await;

    if details_res.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Details error",
        "message": details_res.unwrap_err().to_string()
    }))};

    let mut tx = db.begin().await.expect("Failed to begin transaction");

    let contest_id = Uuid::new_v4();
    let contest_query = sqlx::query(
            "INSERT INTO CONTEST (ID, SPORTFEST_ID, DETAILS_ID, C_TEMPLATE_ID) VALUES (?, ?, ?, ?)"
    )
        .bind(contest_id.clone().to_string())
        .bind(&sf_id.clone())
        .bind(&details_res.as_ref().clone().unwrap().ID)
        .bind(&body.C_TEMPLATE_ID.clone())
        .execute(&mut *tx)
        .await;
    if contest_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Insert contest error",
        "message": contest_query.unwrap_err().to_string(),
    })); };
    if body.HELPERS.is_empty() {
        tx.commit().await.expect("Failed to commit transaction");

        return HttpResponse::Ok().json(json!({
                "status": "success",
                "data": json!({
                    "ID": contest_id.to_string(),
                    "SPORTFEST_ID": sf_id,
                    "DETAILS_ID": details_res.unwrap().ID,
                    "C_TEMPLATE_ID": body.C_TEMPLATE_ID,
                    "HELPERS": serde_json::to_value(body.HELPERS.clone()).unwrap(),
                    })
                }));
    };

    let mut check_helper_query = String::from("SELECT * FROM PERSON WHERE ID IN (");
    for helper in body.HELPERS.clone() {
        check_helper_query += "\"";
        check_helper_query += helper.as_str();
        check_helper_query += "\", ";
    }
    check_helper_query.truncate(check_helper_query.len().saturating_sub(2));
    check_helper_query += ")";

    let check_helper_query = sqlx::query(check_helper_query.as_str()).fetch_all(db.as_ref()).await;
    if check_helper_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Check helper query error",
        "message": check_helper_query.unwrap_err().to_string(),
    })); };

    let helper = check_helper_query.unwrap();
    if helper.len() != body.HELPERS.len() { return HttpResponse::BadRequest().json(json!({
        "status": "Helper error",
        "message": format!("Only {}/{} helper have valid ids",helper.len(), body.HELPERS.len()).as_str()
    })); };

    let mut helper_query = String::from("INSERT INTO HELPER (CONTEST_ID, HELPER_ID, DESCRIPTION) VALUES ");

    for helper in body.HELPERS.clone() {
        helper_query += "(\"";
        helper_query += contest_id.clone().to_string().as_str();
        helper_query += "\", \"";
        helper_query += helper.to_string().as_str();
        helper_query += "\",\"";
        helper_query += "\"), ";
    }
    helper_query.truncate(helper_query.len().saturating_sub(2));

    let helper_query = sqlx::query(helper_query.as_str()).execute(&mut *tx).await;
    if helper_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "error",
        "message": helper_query.unwrap_err().to_string()
    })); };

    tx.commit().await.expect("Failed to commit transaction");

    HttpResponse::Ok().json(json!({
                "status": "success",
                "data": json!({
                        "ID": contest_id.to_string(),
                        "SPORTFEST_ID": sf_id,
                        "DETAILS_ID": details_res.unwrap().ID,
                        "C_TEMPLATE_ID": body.C_TEMPLATE_ID,
                        "HELPER": serde_json::to_value(body.HELPERS.clone()).unwrap(),
                        })
    }))
}
