use crate::api::health::health_checker_handler;
use actix_web::{web};
use crate::api::contactinfo::{contactinfo_create_handler, contactinfo_list_handler};
use crate::api::details::{details_create_handler, details_list_handler};
use crate::api::location::{location_create_handler, location_list_handler};
use crate::api::person::{person_create_handler, person_list_handler};
use crate::api::sportfest::{sportfest_create_handler, sportfest_list_handler};

pub fn config(conf: &mut web::ServiceConfig) {
    let scope = web::scope("")
        .service(health_checker_handler)
        .service(sportfest_list_handler)
        .service(sportfest_create_handler)
        .service(details_list_handler)
        .service(details_create_handler)
        .service(location_list_handler)
        .service(location_create_handler)
        .service(contactinfo_list_handler)
        .service(contactinfo_create_handler)
        .service(person_list_handler)
        .service(person_create_handler);

    conf.service(scope);
}