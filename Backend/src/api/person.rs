use crate::model::person::*;
use actix_web::{get, post,patch, web, HttpResponse, Responder};
use serde_json::json;
use sqlx::MySqlPool;
use uuid::{Uuid};
use random_string::generate;
use crate::api::encryption::encryption::hash;
/*
#[patch("/persons/{id}")]
pub async fn persons_update_handler(body: web::Json<UpdatePerson>,
                                   data: web::Data<AppState>,
                                   path: web::Path<String>)
    -> impl Responder
{
    let person_id = path.into_inner();

    let update_request = body.into_inner();
    let is_role_update = update_request.ROLE.is_some();
    let is_contact_info_update = update_request.CONTACTINFO_ID.is_some();
    if  !is_role_update && !is_contact_info_update {
        return HttpResponse::BadRequest().json({});
    }

    let mut update_as_number = 0;
    if is_role_update { update_as_number += 1; }
    if is_contact_info_update { update_as_number += 2; }
    let mut updated_ci_id = String::from("");
    let mut updated_role = String::from("");

    let result_str = match update_as_number {
        1 => {
            updated_role = update_request.ROLE.unwrap().to_string();
            format!("ROLE = '{}'", updated_role)
        },
        2 => {
            updated_ci_id = update_request.CONTACTINFO_ID.unwrap().to_string();
            format!("CONTACTINFO_ID = '{}'", updated_ci_id)
        },
        3 => {
            updated_role = update_request.ROLE.unwrap().to_string();
            updated_ci_id = update_request.CONTACTINFO_ID.unwrap().to_string();
            format!("CONTACTINFO_ID = '{}', ROLE = '{}'", updated_ci_id, updated_role)
        },
        _ => { String::from("") }
    };


    let query = format!("UPDATE PERSON SET {} WHERE ID = ?", result_str);

    println!("{}",query.clone());

    let result = sqlx::query(query.as_str())
        .bind(person_id.clone())
        .execute(&data.db).await;

    match result {
        Ok(_) => {
            HttpResponse::Ok().json(json!(
            {
                    "status": "success",
                    "updatedPerson": {
                        "ID": person_id,
                        "NEW_ROLE": updated_role,
                        "NEW_CONTACT_INFO_ID": updated_ci_id,
                        }
            }))
        }
        Err(err) => {
            HttpResponse::InternalServerError().json(json!({"status" : format!("{}", err.to_string()) }))
        }
    }

}
*/

#[get("/persons")]
pub async fn persons_get_all_handler(db: web::Data<MySqlPool>) -> impl Responder {
    let query = sqlx::query_as!(
        Person,
        "SELECT * FROM PERSON"
    )
        .fetch_all(db.as_ref())
        .await;

    match query {
        Ok(persons) => HttpResponse::Ok().json(json!({
                "status": "success",
                "results": persons.len(),
                "data": serde_json::to_value(persons).unwrap(),
            }))
        ,
        Err(e) => HttpResponse::InternalServerError().json(json!({
                "status": "error",
                "message": format!("Failed to fetch persons: {}", e),
            }))
    }
}

#[get("/persons/{id}")]
pub async fn persons_get_by_id_handler(
    db: web::Data<MySqlPool>,
    path: web::Path<String>
) -> impl Responder {
    let person_id = path.into_inner();

    let query = sqlx::query_as!(
        Person,
        "SELECT * FROM PERSON WHERE ID = ?",
        person_id
    )
        .fetch_one(db.as_ref())
        .await;

    match query {
        Ok(person) => HttpResponse::Ok().json(json!({
                "status": "success",
                "data": serde_json::to_value(&person).unwrap(),
            }))
        ,
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "error",
            "message": format!("Failed to fetch person: {}", e),
        }))
    }
}

pub async fn create_person(body: CreatePerson, db: &web::Data<MySqlPool>) -> Result<Person, String> {
    let check_if_valid_entry_query = sqlx::query("SELECT * FROM PERSON WHERE EMAIL = ?")
        .bind(body.email.clone())
        .fetch_optional(db.as_ref())
        .await;
    if check_if_valid_entry_query.is_err() { return Err(check_if_valid_entry_query.unwrap_err().to_string());  };
    if check_if_valid_entry_query.unwrap().is_some() { return Err("Email already exists but has to be unique".to_string()); };

    let new_person_id = Uuid::new_v4();

    let query = sqlx::query(
        "INSERT INTO PERSON (ID, FIRSTNAME, LASTNAME, EMAIL, PHONE, GRADE, BIRTH_YEAR, ROLE, GENDER, PICS, PASSWORD) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
        .bind(&new_person_id.to_string())
        .bind(body.first_name.clone())
        .bind(body.last_name.clone())
        .bind(body.email.clone())
        .bind(body.phone.clone())
        .bind(body.grade.clone())
        .bind(body.birth_year.clone())
        .bind(body.role.clone())
        .bind(body.gender.clone())
        .bind(body.pics)
        .bind(body.password.clone())
        .execute(db.as_ref())
        .await;

    match query {
        Ok(_) => Ok( Person {
            ID: new_person_id.to_string(),
            FIRSTNAME: body.first_name,
            LASTNAME: body.last_name,
            EMAIL: body.email,
            PHONE: body.phone,
            GRADE: body.grade,
            BIRTH_YEAR: body.birth_year,
            ROLE: body.role.clone(),
            GENDER: body.gender.clone(),
            PICS: body.pics,
            PASSWORD: body.password.clone()
        }),
        Err(e) => Err(e.to_string())
    }
}

#[post("/persons")]
pub async fn persons_create_handler(body: web::Json<CreatePerson>, db: web::Data<MySqlPool>) -> impl Responder {
    let res = create_person(body.0, &db).await;
    match res {
        Ok(person) => HttpResponse::Ok().json(json!({
            "status": "success",
            "data": serde_json::to_value(&person).unwrap(),
        })),
        Err(e) => HttpResponse::InternalServerError().json(json!({
            "status": "Create Person Error",
            "message": format!("Failed to create person: {}", e),
        }))
    }
}

fn is_email_character(c: char) -> bool { "1234567890.abcdefghijklmnopqrstuvwxyz".contains(c.to_lowercase().nth(0).unwrap()) }

fn find_error_in_csv(csv: &String) -> Option<usize>
{
    let csv_length = csv.len();
    let mut index = 0;
    let n_alphabetic_chars_followed_by_comma = |n_min: usize, n_max: usize, index: &mut usize| -> Option<usize> {
        let mut nr_of_chars_seen = 0;
        while *index < csv_length && csv.chars().nth(*index).unwrap().is_alphabetic() { *index += 1; };
        if nr_of_chars_seen < n_min && n_max < nr_of_chars_seen { return Some(*index); };
        if *index >= csv_length || csv.chars().nth(*index).unwrap() != ',' { return Some(*index); } else { *index += 1; None }
    };

    let mut nr_of_entries = 0;
    while index < csv_length
    {
        // Firstname
        n_alphabetic_chars_followed_by_comma(2, 20, &mut index)?;

        // Lastname
        n_alphabetic_chars_followed_by_comma(2, 20, &mut index)?;

        // Email
        let index_before_at = index;
        while index < csv_length && is_email_character(csv.chars().nth(index).unwrap()) { index += 1;};
        if index < (index_before_at + 1) { return Some(index); };
        if index >= csv_length || csv.chars().nth(index).unwrap() != '@' { return Some(index); } else { index += 1; };
        let index_after_at = index;
        while index < csv_length && is_email_character(csv.chars().nth(index).unwrap()) { index += 1; };
        if index < (index_after_at + 3) { return Some(index); };
        if index >= csv_length || csv.chars().nth(index).unwrap() != ',' { return Some(index); } else { index += 1; };

        // Phone
        let nr_of_digits_in_a_phone_nr = 12;
        let mut nr_of_digits_seen = 0;
        while index < csv_length && csv.chars().nth(index).unwrap().is_ascii_digit() { index += 1; nr_of_digits_seen +=1; };
        if nr_of_digits_in_a_phone_nr != nr_of_digits_seen { return Some(index); };
        if index >= csv_length || csv.chars().nth(index).unwrap() != ',' { return Some(index); } else { index += 1; };

        // Grade
        if index < csv_length && csv.chars().nth(index).unwrap().is_ascii_digit() { index += 1; } else { return Some(index); };
             // optional second digit
             if index < csv_length && csv.chars().nth(index).unwrap().is_ascii_digit() { index += 1; };
        if index < csv_length && csv.chars().nth(index).unwrap().is_alphabetic() { index += 1; } else { return Some(index); };
        if index >= csv_length || csv.chars().nth(index).unwrap() != ',' { return Some(index); } else { index += 1; };

        // Birth year
        let digits_of_birth_year = 4;
        let mut digit_index = 0;
        while index < csv_length && digit_index < digits_of_birth_year {
            if csv.chars().nth(index).unwrap().is_ascii_digit() { index += 1; digit_index += 1; } else { return Some(index); };
        };
        let mut birth_year = 0u32;
        for digit_index in (1..=digits_of_birth_year).rev() {
            birth_year += csv.chars().nth( index-digit_index).unwrap().to_digit(10).unwrap() * 10u32.pow((digit_index - 1) as u32);
        }
        if 2024 < birth_year || birth_year < 1900 { return Some(index-digit_index); };
        if index >= csv_length || csv.chars().nth(index).unwrap() != ',' { return Some(index); } else { index += 1; };

        // Role
        let mut nr_of_role_chars_seen = 0;
        while index < csv_length && csv.chars().nth(index).unwrap().is_alphabetic() { index += 1; nr_of_role_chars_seen += 1;};
        if nr_of_role_chars_seen != 10 && nr_of_role_chars_seen != 5 { return Some(index); };
        let role = &csv[index-nr_of_role_chars_seen..index];
        if role.to_lowercase() != "admin" && role.to_lowercase() != "judge" && role.to_lowercase() != "contestant" { return Some(index); };
        if index >= csv_length || csv.chars().nth(index).unwrap() != ',' { return Some(index); } else { index += 1; };

        // Gender
        n_alphabetic_chars_followed_by_comma(2, 8, &mut index)?;

        // Pics
        n_alphabetic_chars_followed_by_comma(1, 4, &mut index)?;

        if index >= csv_length || csv.chars().nth(index).unwrap() != '\n' { return Some(index); } else { index += 1; };
        nr_of_entries += 1;
        if index == csv_length { break; };
    }

    None
}

#[post("/persons/batch")]
pub async fn persons_create_batch_handler(body: web::Json<PersonBatch>, db: web::Data<MySqlPool>) -> impl Responder {
    let error_in_csv = find_error_in_csv(&body.csv);
    if error_in_csv.is_some() {
        return HttpResponse::BadRequest().json(json!({
            "status": "Bad csv error",
            "message": format!("Error at position: {}", error_in_csv.unwrap())
        }));
    };

    let mut person_query = String::from("INSERT INTO PERSON (ID, FIRSTNAME, LASTNAME, EMAIL, PHONE, GRADE, BIRTH_YEAR, ROLE, GENDER, PICS, PASSWORD) VALUES ");

    let mut passwords_and_ids = Vec::<(String,String)>::with_capacity(30);
    let mut index = 0;
    while index < body.csv.len() {
        let parse = |length: usize, index: &mut usize, delimiter: char|-> String {
            let mut value = String::with_capacity(length);
            while body.csv.chars().nth(*index).unwrap() != delimiter {value.push(body.csv.chars().nth(*index).unwrap()); *index += 1};
            *index += 1; // skip comma
            value
        };

        let id = Uuid::new_v4();
        let first_name = parse(8, &mut index, ',');
        let last_name = parse(10, &mut index, ',');
        let email = parse(24, &mut index, ',');
        let phone = parse(12, &mut index, ',');
        let grade = parse(4, &mut index, ',');
        let birth_year = parse(4, &mut index, ',');
        let role = parse(10, &mut index, ',');
        let gender = parse(8, &mut index, ',');
        let pics = parse(1, &mut index, '\n');
        let password = generate(8, "abcdefghijklmnopqrstuvwxyz1234567890");

        let mut append = String::with_capacity(8+10+24+12+4+4+10+8+1+8+31);
        append.push_str("(\"");
        append.push_str(id.to_string().as_str());
        append.push_str("\", \"");
        append.push_str(first_name.as_str());
        append.push_str("\", \"");
        append.push_str(last_name.as_str());
        append.push_str("\", \"");
        append.push_str(email.as_str());
        append.push_str("\", \"");
        append.push_str(phone.as_str());
        append.push_str("\", \"");
        append.push_str(grade.as_str());
        append.push_str("\", \"");
        append.push_str(birth_year.as_str());
        append.push_str("\", \"");
        append.push_str(role.as_str());
        append.push_str("\", \"");
        append.push_str(gender.as_str());
        append.push_str("\", ");
        append.push_str(pics.as_str());
        append.push_str(", \"");
        append.push_str(password.as_str());
        append.push_str("\"), ");

        person_query.push_str(append.as_str());

        passwords_and_ids.push((id.to_string(), password));

        // skip newline
        index += 1;
    }
    // Remove excessive ", "
    person_query = person_query[..person_query.len()-2].to_string();

    let query = sqlx::query(&person_query)
        .execute(db.as_ref())
        .await;
    if query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Insert persons error",
        "message": query.unwrap_err().to_string()
    }));};

    HttpResponse::Ok().json(json!({
        "status": "success",
        "Created_persons": passwords_and_ids.len()
    }))

    // Send emails with passwords.


}






