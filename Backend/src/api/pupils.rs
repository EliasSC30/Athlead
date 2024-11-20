use crate::model::pupil::*;
use crate::AppState;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;

#[get("/pupils")]
pub async fn pupil_list_handler(data: web::Data<AppState>) -> impl Responder {
   let pupils: Vec<Pupil> = sqlx::query_as!(
       Pupil,
       r#"SELECT * FROM Pupils"#)
       .fetch_all(&data.db)
       .await
       .unwrap();

    let pupil_response = pupils.into_iter().map(|pupil| {
        json!({
            "id": pupil.id,
            "firstname": pupil.firstname,
            "lastname": pupil.lastname,
            "email": pupil.email,
            "created_at": pupil.created_at,
        })
    }).collect::<Vec<serde_json::Value>>();

    HttpResponse::Ok().json(json!({
        "status": "success",
        "results": pupil_response.len(),
        "data": pupil_response,
    }))

}

#[post("/pupils")]
pub async fn pupil_create_handler(body: web::Json<CreatePupil>, data:web::Data<AppState>) -> impl Responder {
    let new_pupil_id = uuid::Uuid::new_v4().to_string();
    let query = sqlx::query(
        r#"INSERT INTO pupils (id, firstname, lastname, email, password, created_at) VALUES (?, ?, ?, ?, ?, ?)"#)
        .bind(new_pupil_id.clone())
        .bind(body.firstname.to_string())
        .bind(body.lastname.to_string())
        .bind(body.email.to_string())
        .bind(body.password.to_string())
        .bind(chrono::Local::now().to_string())
        .execute(&data.db)
        .await.map_err(|e: sqlx::Error| e.to_string());

    if let Err(e) = query {
        return HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": "Failed to create pupil, with error: ".to_owned() + &e.to_string(),
        }))
    }

    let query = sqlx::query_as!(
        Pupil,
        r#"SELECT * FROM pupils WHERE id = ?"#,
        new_pupil_id
    ).fetch_one(&data.db).await;

    match query {
        Ok(pupil) => {
            let json_response = json!({
                "status": "success",
                "message": "Pupil created successfully!",
                "data": {
                    "id": pupil.id,
                    "firstname": pupil.firstname,
                    "lastname": pupil.lastname,
                    "email": pupil.email,
                    "created_at": pupil.created_at,
                }
            });
            HttpResponse::Created().json(json_response)
        }
        Err(e) => {
            HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": "Failed to fetch created pupil, with error: ".to_owned() + &e.to_string(),
            }))
        }
    }

}
