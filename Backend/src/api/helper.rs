use actix_web::{patch, web, HttpRequest, HttpResponse, Responder};
use actix_web::web::Path;
use actix_web::web::Data;
use serde_json::json;
use sqlx::MySqlPool;
use crate::api::general::get_user_of_request;
use crate::model::contest::Contest;
use crate::model::person::PatchHelper;
use crate::model::helper::Helper;


pub struct IDWrapper {
    pub id: String,
}
#[patch("/contests/{contest_id}/helper/{helper_id}")]
pub async fn contests_helper_patch(db: Data<MySqlPool>, path: Path<(String,String)>, req: HttpRequest, body: web::Json<PatchHelper>) -> impl Responder {
    let (ct_id, helper_id) = path.into_inner();

    let user = get_user_of_request(req);
    if user.is_err() { return HttpResponse::Unauthorized().json(json!({"status": "Unauthorized"})); };
    let user = user.unwrap();
    let mut is_allowed_to_patch = user.ROLE.to_lowercase() == "admin"; // Admin is always allowed to patch

    let contest_judge_query =
        sqlx::query_as!(IDWrapper, "SELECT ct.ID as id FROM CONTEST as ct JOIN DETAILS as d ON d.CONTACTPERSON_ID = ?", user.ID.clone())
            .fetch_all(db.as_ref()).await;
    if contest_judge_query.is_err() { return HttpResponse::InternalServerError().json(json!({"status": "No contactperson found"})); };
    let contest_judge_query = contest_judge_query.unwrap();
    is_allowed_to_patch = is_allowed_to_patch || contest_judge_query.len() == 1; // Judge of contests is allowed to change


    let contest_query = sqlx::query_as!(Contest, "SELECT * FROM CONTEST WHERE ID = ?", ct_id.clone()).fetch_one(db.as_ref()).await;
    if contest_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Contest was not found",
        "message": contest_query.unwrap_err().to_string()
    })); };

    let helper_query = sqlx::query_as!(Helper, r#"SELECT CONTEST_ID as contest_id,
                                                         HELPER_ID as helper_id,
                                                         DESCRIPTION as description
                        FROM HELPER WHERE CONTEST_ID = ? AND HELPER_ID = ?"#, ct_id.clone(), helper_id.clone())
        .fetch_one(db.as_ref()).await;
    if helper_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "No helper found",
        "message": helper_query.unwrap_err().to_string()
    })); };
    let helper = helper_query.unwrap();
    is_allowed_to_patch = is_allowed_to_patch || helper.helper_id == helper_id; // Everyone's allowed to change their own

    if !is_allowed_to_patch { return HttpResponse::Unauthorized().json(json!({
        "status": "Unauthorized",
    })); };

    let update_query = format!("UPDATE HELPER SET DESCRIPTION = \"{}\" WHERE CONTEST_ID = \"{}\" AND HELPER_ID = \"{}\"",
    body.description, ct_id, helper_id);
    let update_query = sqlx::query(&update_query).execute(db.as_ref()).await;
    if update_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Update Helper error",
        "message": update_query.unwrap_err().to_string()
    })); };


   HttpResponse::Ok().json(json!({"status": "success"}))
}


