use actix_web::{patch, web, HttpRequest, HttpResponse, Responder};
use actix_web::web::Path;
use actix_web::web::Data;
use serde_json::json;
use sqlx::MySqlPool;
use crate::api::general::get_user_of_request;
use crate::model::contest::Contest;
use crate::model::person::PatchHelper;

#[patch("/contests/{contest_id}/helper/{helper_id}")]
pub async fn contest_helper_patch(db: Data<MySqlPool>, path: Path<(String,String)>, req: HttpRequest, body: web::Json<PatchHelper>) -> impl Responder {
    let user = get_user_of_request(req);
    if user.is_err() { return HttpResponse::Unauthorized().json(json!({"status": "Unauthorized"})); };
    let user = user.unwrap();
    let mut is_allowed_to_patch = user.ROLE.to_lowercase() == "admin";

    let (ct_id, helper_id) = path.into_inner();

    let contest_query = sqlx::query_as!(Contest, "SELECT * FROM CONTEST WHERE ID = ?", ct_id).fetch_one(db.as_ref()).await;
    if contest_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Contest was not found",
        "message": contest_query.unwrap_err().to_string()
    })); };

   HttpResponse::Ok().json(contest_query.unwrap())




}


