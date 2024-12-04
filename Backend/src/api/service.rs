use crate::api::health::health_checker_handler;
use actix_web::{web};
use actix_web::web::service;
use crate::api::contactinfo::{contactinfos_create_handler, contactinfos_get_by_id_handler, contactinfos_get_all_handler, contactinfos_update_handler};
use crate::api::contest::{contests_create_results, contest_get_results_by_id_handler, contests_get_master_view_handler, contests_create_handler};
use crate::api::contestresult::contestresult_create_handler;
use crate::api::ctemplate::{ctemplate_create_handler, ctemplates_get_by_id_handler, ctemplates_get_all_handler};
use crate::api::details::{details_create_handler, details_get_by_id_handler, details_get_all_handler, details_update_handler};
use crate::api::location::{locations_create_handler, locations_get_by_id_handler, locations_get_all_handler, locations_update_handler};
use crate::api::person::{persons_update_handler, persons_create_handler, persons_get_by_id_handler, persons_get_all_handler};
use crate::api::sportfest::{create_contest_for_sf_handler, sportfests_create_handler, sportfests_get_masterview_handler, sportfests_list_handler, sportfests_update_handler};

pub fn config(conf: &mut web::ServiceConfig) {
    let scope = web::scope("")
        // Health
        .service(health_checker_handler)

        // Sportfest
        .service(sportfests_list_handler) // for now simply queries db content of sf table
        .service(sportfests_create_handler)
        .service(sportfests_get_masterview_handler)
        .service(sportfests_update_handler) // wip, takes id's not attributes
        .service(create_contest_for_sf_handler)

        // Details
        .service(details_get_all_handler)
        .service(details_get_by_id_handler)
        .service(details_create_handler) // works but needs location and contact-person id
        .service(details_update_handler) // wip, probably works but takes ids

        // Location
        .service(locations_get_all_handler)
        .service(locations_get_by_id_handler)
        .service(locations_create_handler)
        .service(locations_update_handler)

        // ContactInfos
        .service(contactinfos_get_all_handler)
        .service(contactinfos_create_handler)
        .service(contactinfos_get_by_id_handler)
        .service(contactinfos_update_handler) // works but two fields are missing

        // Persons
        .service(persons_get_all_handler) // wip, works but returns contactinfo id
        .service(persons_get_by_id_handler)
        .service(persons_update_handler)// wip, works but only role and contactinfo_id can be updated
        .service(persons_create_handler)

        // C_Templates
        .service(ctemplates_get_all_handler)
        .service(ctemplates_get_by_id_handler)
        .service(ctemplate_create_handler)


        // Contests
        // No getters since all fields are ids, only complex getters are useful
        .service(contest_get_results_by_id_handler)
        .service(contests_create_results)
        .service(contests_create_handler)
        .service(contests_get_master_view_handler)

        // ContestResults
        .service(contestresult_create_handler);
    conf.service(scope);
}