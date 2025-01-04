use actix_web::{get, patch, web::Json, web::Path, HttpRequest, HttpResponse, Responder};
use actix_web::web::Data;
use serde_json::json;
use sqlx::{MySqlPool, Row};
use crate::api::general::get_user_of_request;
use crate::model::person::{Person};
use crate::model::parent_children::{ParentChildren, UpdateChild};

#[get("/parents/children")]
pub async fn parents_get_children_handler(req: HttpRequest, db: Data<MySqlPool>) -> impl Responder {
    let user = get_user_of_request(req);
    if user.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Invalid user error"
    })); };
    let user = user.unwrap();

    let parents_query =
        sqlx::query_as!(ParentChildren, "SELECT * FROM PARENT WHERE PARENT_ID = ?", user.ID)
            .fetch_all(db.as_ref())
            .await;

    if parents_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Internal server error",
    })); };

    let found_entries = parents_query.unwrap();
    if found_entries.len() == 0 { return HttpResponse::Ok().json(json!({
        "status": "success",
        "data": []
    })) };

    let mut children_query = String::from("SELECT * FROM PERSON WHERE ID IN (");
    for child in found_entries {
        children_query += "\"";
        children_query += child.CHILD_ID.clone().as_str();
        children_query += "\", \"";
    }
    children_query = children_query[..children_query.len()-3].to_string();

    children_query += ")";

    let children_query = sqlx::query(children_query.as_str()).fetch_all(db.as_ref()).await;
    if children_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Internal server error",
    })); };
    let children = children_query.unwrap();
    let children = children.into_iter().map(|row| Person {
        ID: row.try_get("ID").unwrap(),
        FIRSTNAME: row.try_get("FIRSTNAME").unwrap(),
        LASTNAME: row.try_get("LASTNAME").unwrap(),
        EMAIL: row.try_get("EMAIL").unwrap(),
        PHONE: row.try_get("PHONE").unwrap(),
        BIRTH_YEAR: row.try_get("BIRTH_YEAR").unwrap(),
        ROLE: row.try_get("ROLE").unwrap(),
        GRADE: row.try_get("GRADE").unwrap(),
        GENDER: row.try_get("GENDER").unwrap(),
        PICS: row.try_get("PICS").unwrap(),
        PASSWORD: "".to_string(),
        DISABILITIES: row.try_get("DISABILITIES").unwrap(),

    } ).collect::<Vec<Person>>();

    HttpResponse::Ok().json(json!({
        "status": "success",
        "data": serde_json::to_value(children).unwrap()
    }))
}

#[patch("/parents/children/{child_id}")]
pub async fn parents_children_patch_child_handler(path: Path<String>,
                                                  db: Data<MySqlPool>,
                                                  req: HttpRequest,
                                                  body: Json<UpdateChild>
) -> impl Responder {
    let child_id = path.into_inner();
    let user = get_user_of_request(req);
    if user.is_err() { return HttpResponse::InternalServerError().json(json!({"status": "Invalid user error"})); };
    let user = user.unwrap();

    if body.pics.is_none() && body.disabilities.is_none() {
        return HttpResponse::BadRequest().json(json!({
            "status": "Neither pics or disabilities sent"
        }));
    };

    let parents_query =
        sqlx::query_as!(ParentChildren, "SELECT * FROM PARENT WHERE PARENT_ID = ? AND CHILD_ID = ?",
        user.ID, child_id.clone()).fetch_one(db.as_ref()).await;
    if parents_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Parent query error",
        "message": parents_query.unwrap_err().to_string()
    })); };

    let mut update_query = String::from("UPDATE PERSON SET ");

    if body.pics.is_some() {
        update_query += format!("PICS = {}, ", body.pics.as_ref().clone().unwrap()).as_str();
    }
    if body.disabilities.is_some() {
        update_query += format!("DISABILITIES = \"{}\", ", body.disabilities.as_ref().clone().unwrap()).as_str();
    }
    update_query.truncate(update_query.len() - 2);
    update_query += format!(" WHERE ID = \"{}\"", child_id).as_str();
    println!("Update query: {}", update_query);
    let update_query = sqlx::query(update_query.as_str()).execute(db.as_ref()).await;
    if update_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Update person error",
        "message": update_query.unwrap_err().to_string()
    })); };

    HttpResponse::Ok().json(json!({
        "status": "success",
    }))
}

