use crate::api::health::health_checker_handler;
use actix_web::{web};
use crate::api::contactinfo::{contactinfos_create_handler, contactinfos_get_handler, contactinfos_list_handler, contactinfos_update_handler};
use crate::api::details::{details_create_handler, details_get_handler, details_list_handler};
use crate::api::location::{locations_create_handler, locations_get_handler, locations_list_handler};
use crate::api::person::{persons_update_handler, persons_create_handler, persons_get_handler, persons_list_handler};
use crate::api::sportfest::{sportfests_create_handler, sportfests_get_handler, sportfests_list_handler};

pub fn config(conf: &mut web::ServiceConfig) {
    let scope = web::scope("")
        .service(health_checker_handler)
        .service(sportfests_list_handler)
        .service(sportfests_create_handler)
        .service(sportfests_get_handler)
        .service(details_list_handler)
        .service(details_get_handler)
        .service(details_create_handler)
        .service(locations_list_handler)
        .service(locations_get_handler)
        .service(locations_create_handler)
        .service(contactinfos_list_handler)
        .service(contactinfos_create_handler)
        .service(contactinfos_get_handler)
        .service(persons_list_handler)
        .service(persons_get_handler)
        .service(persons_update_handler)
        .service(contactinfos_update_handler)
        .service(persons_create_handler);

    conf.service(scope);
}