use crate::api::health::health_checker_handler;
use actix_web::{web};
use crate::api::contactinfo::{contactinfos_create_handler, contactinfos_get_handler, contactinfos_list_handler, contactinfos_update_handler};
use crate::api::contest::{contests_create_results, contests_get_results_handler, contests_get_master_view_handler};
use crate::api::ctemplate::{create_ctemplate_handler, ctemplates_get_by_id_handler, ctemplates_get_handler};
use crate::api::details::{details_create_handler, details_get_handler, details_list_handler, details_update_handler};
use crate::api::location::{locations_create_handler, locations_get_handler, locations_list_handler, locations_update_handler};
use crate::api::person::{persons_update_handler, persons_create_handler, persons_get_handler, persons_list_handler};
use crate::api::sportfest::{create_contest_for_sf_handler, sportfests_create_handler, sportfests_get_handler, sportfests_list_handler, sportfests_update_handler};

pub fn config(conf: &mut web::ServiceConfig) {
    let scope = web::scope("")
        // Health
        .service(health_checker_handler)

        // Sportfest
        .service(sportfests_list_handler) // for now simply queries db content of sf table
        .service(sportfests_create_handler) // works
        .service(sportfests_get_handler)
        .service(sportfests_update_handler)
        .service(create_contest_for_sf_handler)

        // Details
        .service(details_list_handler)
        .service(details_get_handler)
        .service(details_create_handler)
        .service(details_update_handler)

        // Location
        .service(locations_list_handler)
        .service(locations_get_handler)
        .service(locations_create_handler)
        .service(locations_update_handler)

        // ContactInfos
        .service(contactinfos_list_handler)
        .service(contactinfos_create_handler)
        .service(contactinfos_get_handler)
        .service(contactinfos_update_handler)

        // Persons
        .service(persons_list_handler)
        .service(persons_get_handler)
        .service(persons_update_handler)
        .service(persons_create_handler)

        // C_Templates
        .service(create_ctemplate_handler)
        .service(ctemplates_get_handler)
        .service(ctemplates_get_by_id_handler)


        // Contests
        .service(contests_create_results)
        .service(contests_get_results_handler)
        .service(contests_get_master_view_handler)
;
    conf.service(scope);
}