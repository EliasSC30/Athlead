use actix_web::{get, HttpMessage, HttpRequest, HttpResponse, Responder};
use actix_web::web::Data;
use serde_json::json;
use sqlx::{MySqlPool, Row};
use crate::model::person::{Person};
use crate::model::parent_children::{ParentChildren};

#[get("/parents/children")]
pub async fn parents_get_children_handler(req: HttpRequest, db: Data<MySqlPool>) -> impl Responder {
    let container = req.extensions();
    let user = container.get::<Person>();
    if user.is_none() { return HttpResponse::InternalServerError().json(json!({
        "status": "User was none error",
        "message": "Should not happen..",
    }))};
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
    } ).collect::<Vec<Person>>();

    HttpResponse::Ok().json(json!({
        "status": "success",
        "data": serde_json::to_value(children).unwrap()
    }))
}