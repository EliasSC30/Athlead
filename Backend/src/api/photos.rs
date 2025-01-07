use std::fs::File;
use std::io::{Read, Write};
use actix_web::{post, get, HttpResponse, Responder};
use actix_web::web::{Json, Path};
use serde_json::json;
use crate::model::photos::{PhotoUpload, Photoname};

const SAVE_DIR: &'static str = "./images";

#[post("/photos")]
pub async fn photos_post_handler(body: Json<PhotoUpload>) -> impl Responder {
    let file_path = format!("{}/{}", SAVE_DIR, body.name);

    if let Err(e) = std::fs::create_dir_all(SAVE_DIR) {
        return HttpResponse::InternalServerError()
            .body(format!("Failed to create directory: {}", e));
    }

    let created_file = File::create(&file_path).and_then(|mut file| {
        file.write_all((&body.data).as_ref())
    });
    if created_file.is_err() {
        return HttpResponse::InternalServerError().json(json!({
            "status": format!("Couldn't save file: {}", created_file.err().unwrap())
        }));
    }

    HttpResponse::Ok().json(json!({ "status": "success" }))
}

#[get("/photos/{id}")]
pub async fn photos_get_handler(path: Path<String>) -> impl Responder {
    let user_id = path.into_inner();
    let file_path = format!("{}/{}", SAVE_DIR, user_id);

    let mut file = File::open(&file_path);
    if file.is_err() {
        return HttpResponse::InternalServerError().json(json!({"status": format!("Couldn't open file: {}", file.unwrap_err())}));
    };
    let mut file = file.unwrap();

    let mut data = String::with_capacity(10 * 1024);
    let res = file.read_to_string(&mut data);
    if res.is_err() {
        return HttpResponse::InternalServerError().json(json!({
            "status": "Couldn't read file"
        }));
    };


    HttpResponse::Ok().json(json!({
        "status": "success",
        "data": data
    }))
}


