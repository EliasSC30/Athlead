use crate::api::health::health_checker_handler;
use actix_web::{web};
use crate::api::class::class_list_handler;
use crate::api::pupils::{pupil_create_handler, pupil_list_handler};

pub fn config(conf: &mut web::ServiceConfig) {
    let scope = web::scope("")
        .service(health_checker_handler)
        .service(pupil_list_handler)
        .service(pupil_create_handler)
        .service(class_list_handler);

    conf.service(scope);
}