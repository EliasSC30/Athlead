use crate::api::health::health_checker_handler;
use actix_web::{web};
use crate::api::contest::{contests_create_results, contest_get_results_by_id_handler, contests_get_master_view_handler, contests_create_handler, contests_create_participants_handler, contests_judge_mycontests_handler, contests_get_participants_handler, contests_participants_mycontests_handler, contests_patch_results, contests_check_participant_handler};
use crate::api::contestresult::{contestresults_patch_handler};
use crate::api::ctemplate::{ctemplate_create_handler, ctemplates_get_by_id_handler, ctemplates_get_all_handler};
use crate::api::details::{details_create_handler, details_get_by_id_handler, details_get_all_handler, details_update_handler};
use crate::api::location::{locations_create_handler, locations_get_by_id_handler, locations_get_all_handler, locations_update_handler};
use crate::api::loggedin::get_logged_in_handler;
use crate::api::logon::{login_handler, register_handler};
use crate::api::parent_children::{parents_children_patch_child_handler, parents_get_children_handler};
use crate::api::person::{persons_create_handler, persons_get_by_id_handler, persons_get_all_handler, persons_create_batch_handler};
use crate::api::sportfest::{create_contest_for_sf_handler, sportfests_create_handler, sportfests_create_with_location_handler, sportfests_get_masterview_handler, sportfests_get_results_by_id_handler, sportfests_list_handler, sportfests_patch_handler};

pub fn config(conf: &mut web::ServiceConfig) {
    let scope = web::scope("")
        // Health
        .service(health_checker_handler)

        // Sportfest
        .service(sportfests_list_handler) // for now simply queries db content of sf table
        .service(sportfests_create_handler)
        .service(sportfests_create_with_location_handler)
        .service(sportfests_get_masterview_handler)
        .service(sportfests_get_results_by_id_handler)
        .service(sportfests_patch_handler)
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

        // Persons
        .service(persons_get_all_handler)
        .service(persons_get_by_id_handler)
        .service(persons_create_handler)
        .service(persons_create_batch_handler)

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
        .service(contests_create_participants_handler)
        .service(contests_judge_mycontests_handler)
        .service(contests_get_participants_handler)
        .service(contests_participants_mycontests_handler)
        .service(contests_patch_results)
        .service(contests_check_participant_handler)

        // ContestResults
        .service(contestresults_patch_handler)

        // Logon
        .service(register_handler)
        .service(login_handler)

        // Logged in
        .service(get_logged_in_handler)

        // Parents
        .service(parents_get_children_handler)
        .service(parents_children_patch_child_handler)
        ;

    conf.service(scope);
}