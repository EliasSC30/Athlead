use crate::model::person::*;
use actix_web::{get, post, web, HttpResponse, Responder};
use serde_json::json;
use sqlx::{MySqlPool, Row};
use uuid::{Uuid};
use random_string::generate;

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
            PASSWORD: body.password.clone(),
            DISABILITIES: body.disabilities.clone()
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
        while *index < csv_length && csv.chars().nth(*index).unwrap().is_alphabetic() { *index += 1; nr_of_chars_seen += 1; };
        if nr_of_chars_seen < n_min || n_max < nr_of_chars_seen { return Some(*index); };
        if *index >= csv_length || csv.chars().nth(*index).unwrap() != ',' { Some(*index) } else { *index += 1; None }
    };

    let email_followed_by = |delimiter: char, index: &mut usize| -> Option<usize> {
        let index_before_at = *index;
        while *index < csv_length && is_email_character(csv.chars().nth(*index).unwrap()) { *index += 1;};
        if *index < (index_before_at + 1) { return Some(*index); };
        if *index >= csv_length || csv.chars().nth(*index).unwrap() != '@' { return Some(*index); } else { *index += 1; };
        let index_after_at = *index;
        while *index < csv_length && is_email_character(csv.chars().nth(*index).unwrap()) { *index += 1; };
        if *index < (index_after_at + 3) { return Some(*index); };
        if *index >= csv_length || csv.chars().nth(*index).unwrap() != delimiter { Some(*index) } else { *index += 1; None }
    };

    while index < csv_length && csv.chars().nth(index).unwrap() != ';' {
        // Firstname
        if let Some(err_index) = n_alphabetic_chars_followed_by_comma(2, 20, &mut index) {
            return Some(err_index);
        };

        // Lastname
        if let Some(err_index) = n_alphabetic_chars_followed_by_comma(2, 20, &mut index) {
            return Some(err_index);
        };

        // Email
        if let Some(err_index) = email_followed_by(',', &mut index){
            return Some(err_index);
        };

        // Phone
        let nr_of_digits_in_a_phone_nr = 12;
        let mut nr_of_digits_seen = 0;
        while index < csv_length && csv.chars().nth(index).unwrap().is_ascii_digit() { index += 1; nr_of_digits_seen +=1; };
        if nr_of_digits_in_a_phone_nr != nr_of_digits_seen { return Some(index); };
        if index >= csv_length || csv.chars().nth(index).unwrap() != '\n' { return Some(index); } else { index += 1; };
    };
    index += 1;
    if index >= csv_length || csv.chars().nth(index).unwrap() != '\n' { return Some(index); } else { index += 1; };
    // End of parents, start of children

    while index < csv_length
    {
        // Firstname
        if let Some(err_index) = n_alphabetic_chars_followed_by_comma(2, 20, &mut index) {
            return Some(err_index);
        };

        // Lastname
        if let Some(err_index) = n_alphabetic_chars_followed_by_comma(2, 20, &mut index) {
            return Some(err_index);
        };

        // Email
        if let Some(err_index) = email_followed_by(',', &mut index){
            return Some(err_index);
        };

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
        if let Some(err_index) = n_alphabetic_chars_followed_by_comma(2, 8, &mut index) {
            return Some(err_index);
        }

        // Pics
        if index >= csv_length || (csv.chars().nth(index).unwrap() != '1' && csv.chars().nth(index).unwrap() != '0')
        { return Some(index); } else { index += 1; };
        if index >= csv_length || csv.chars().nth(index).unwrap() != ',' { return Some(index); } else { index += 1; };

        // First parent email
        let index_before_first_email = index;
        if let Some(_) = email_followed_by('\n', &mut index){
            index = index_before_first_email;
            if let Some(err_index) = email_followed_by(',', &mut index){
                return Some(err_index);
            };

            // Optional second parent email
            if let Some(err_index) = email_followed_by('\n', &mut index){
                return Some(err_index);
            };
        };

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

    let mut tx = db.begin().await.expect("Db error");

    let mut passwords_and_emails = Vec::<(String,String)>::with_capacity(30);

    let mut parents_query = String::from("INSERT INTO PERSON (ID, FIRSTNAME, LASTNAME, EMAIL, PHONE, GRADE, BIRTH_YEAR, ROLE, GENDER, PICS, PASSWORD) VALUES ");
    let mut index = 0;
    while body.csv.chars().nth(index).unwrap() != ';' {
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
        let phone = parse(12, &mut index, '\n');
        let password = generate(8, "abcdefghijklmnopqrstuvwxyz1234567890");

        let mut append = String::with_capacity(8+10+24+12+4+4+10+8+1+8+31);
        append.push_str("(\"");
        append.push_str(id.to_string().as_str());
        append.push_str("\", \"");
        append.push_str(first_name.as_str());
        append.push_str("\", \"");
        append.push_str(last_name.as_str());
        append.push_str("\", \"");
        append.push_str(email.clone().as_str());
        append.push_str("\", \"");
        append.push_str(phone.as_str());
        append.push_str("\", ");
        append.push_str("NULL");
        append.push_str(", ");
        append.push_str("NULL");
        append.push_str(", \"");
        append.push_str("Contestant");
        append.push_str("\", \"");
        append.push_str("Unknown");
        append.push_str("\", ");
        append.push_str("0");
        append.push_str(", \"");
        append.push_str(password.as_str());
        append.push_str("\"), ");

        passwords_and_emails.push((email, password));
        parents_query.push_str(append.as_str());
    }
    parents_query = parents_query[..parents_query.len()-2].to_string();

    let parents_query = sqlx::query(&parents_query).execute(&mut *tx).await;
    if parents_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": format!("Insert Parents error\n{}", parents_query.unwrap_err().to_string()).as_str()
    })); };

    // End of parents, start of children
    index += 2;

    let mut children_query = String::from("INSERT INTO PERSON (ID, FIRSTNAME, LASTNAME, EMAIL, PHONE, GRADE, BIRTH_YEAR, ROLE, GENDER, PICS, PASSWORD) VALUES ");

    let mut parents_and_child = Vec::<(String,String, Option<String>)>::with_capacity(30);
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
        let pics = parse(1, &mut index, ',');
        let password = generate(8, "abcdefghijklmnopqrstuvwxyz1234567890");

        let mut first_parent_email = String::with_capacity(24);
        while body.csv.chars().nth(index).unwrap() != ',' &&
              body.csv.chars().nth(index).unwrap() != '\n' {
            first_parent_email.push(body.csv.chars().nth(index).unwrap()); index += 1
        };
        let mut second_parent_email: Option<String> = None;
        if body.csv.chars().nth(index).unwrap() == ',' {
            index += 1;
            let mut local = String::with_capacity(24);
            while body.csv.chars().nth(index).unwrap() != '\n' {
                local.push(body.csv.chars().nth(index).unwrap()); index += 1
            };
            second_parent_email = Some(local);
        }

        let mut append = String::with_capacity(8+10+24+12+4+4+10+8+1+8+31);
        append.push_str("(\"");
        append.push_str(id.to_string().as_str());
        append.push_str("\", \"");
        append.push_str(first_name.as_str());
        append.push_str("\", \"");
        append.push_str(last_name.as_str());
        append.push_str("\", \"");
        append.push_str(email.clone().as_str());
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

        children_query.push_str(append.as_str());

        passwords_and_emails.push((email.clone(), password));
        parents_and_child.push((email, first_parent_email, second_parent_email));

        // skip newline
        index += 1;
    }
    // Remove excessive ", "
    children_query = children_query[..children_query.len()-2].to_string();

    let children_query = sqlx::query(&children_query)
        .execute(&mut *tx)
        .await;
    if children_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Insert children error",
        "message": children_query.unwrap_err().to_string()
    }));};

    let mut parent_to_child_query = String::from("INSERT INTO PARENT (PARENT_ID, CHILD_ID) VALUES ");

    for (child_email, first_parent_email, second_parent_email) in parents_and_child {
        let mut emails_to_check = vec![child_email.clone(), first_parent_email.clone()];
        if second_parent_email.is_some() { emails_to_check.push(second_parent_email.clone().unwrap().clone()); };

        let mut email_query = format!("SELECT * FROM PERSON WHERE EMAIL IN (\"{}\", \"{}\"", child_email, first_parent_email);
        if second_parent_email.is_some() {
            email_query += format!(", \"{}\")", second_parent_email.clone().unwrap().clone()).as_str();
        } else {
            email_query += ")";
        };
        let email_query = sqlx::query(&email_query).fetch_all(&mut *tx).await;
        if email_query.is_err() { return HttpResponse::InternalServerError().json(json!({
            "status": "Get Person by email query error",
        })); };
        let id_and_emails = email_query.unwrap().into_iter().map( |row| {
            (row.try_get("ID").unwrap(),row.try_get("EMAIL").unwrap())
        }).collect::<Vec<(String,String)>>();
        if id_and_emails.len() != emails_to_check.len() { return HttpResponse::InternalServerError().json(json!({
            "status": "Some email was not found",
        })); };

        let mut child_id = String::from("");
        id_and_emails.iter().for_each(|info| { if info.1 == child_email {child_id = info.0.clone()} });
        let mut first_parent_id = String::from("");
        id_and_emails.iter().for_each(|info| { if info.1 == first_parent_email {first_parent_id = info.0.clone()} });
        let mut second_parent_id: Option<String> = if second_parent_email.is_some() {
                let mut ret: Option<String> = None;
                id_and_emails.iter().for_each(|info| {
                    if info.1 == second_parent_email.clone().unwrap() {
                        ret = Some(info.0.clone())
                    }
                });
                ret
        } else { None };

        parent_to_child_query += "(\"";
        parent_to_child_query += first_parent_id.as_str();
        parent_to_child_query += "\", \"";
        parent_to_child_query += child_id.as_str();
        parent_to_child_query += "\"), ";
        if second_parent_id.is_none() {continue;};

        parent_to_child_query += "(\"";
        parent_to_child_query += second_parent_id.unwrap().as_str();
        parent_to_child_query += "\", \"";
        parent_to_child_query += child_id.as_str();
        parent_to_child_query += "\"), ";
    }
    parent_to_child_query = parent_to_child_query[..parent_to_child_query.len()-2].to_string();
    let parents_query = sqlx::query(&parent_to_child_query).execute(&mut *tx).await;
    if parents_query.is_err() { return HttpResponse::InternalServerError().json(json!({
        "status": "Insert persons error",
    })); };

    tx.commit().await.expect("Error commit transaction");

    HttpResponse::Ok().json(json!({
        "status": "success",
        "Created_persons": passwords_and_emails.len(),
    }))

    // Send emails with passwords.
}






