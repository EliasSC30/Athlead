use crate::api::health::health_checker_handler;
use actix_web::{web};
pub fn config(conf: &mut web::ServiceConfig) {
    let scope = web::scope("")
        .service(health_checker_handler);

    conf.service(scope);
}