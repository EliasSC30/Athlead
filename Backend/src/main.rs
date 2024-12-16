
mod api;
mod model;

use actix_cors::Cors;
use actix_web::middleware::Logger;
use actix_web::{http::header, web, App, HttpServer};
use dotenv::dotenv;
use sqlx::mysql::{MySqlPool, MySqlPoolOptions};
use actix_web::middleware::{self, Next};
use actix_web::{dev::{ServiceRequest, ServiceResponse},web::Path, Error, cookie::Cookie, body::MessageBody};
use actix_web::error::ErrorBadRequest;
use actix_web::http::Method;
use crate::api::logon::check_token;

const ADMIN_REQUESTS: [(&'static str, &'static str);1] = [("GET", "/details")];
const JUDGE_REQUESTS: [(&'static str, &'static str);1] = [("GET", "/sportfests")];

pub fn string_to_auth_level(role: &String) -> Result<AuthLevel, Error> {
    match role.as_str().to_lowercase().as_str() {
        "admin" => Ok(AuthLevel::Admin),
        "judge" => Ok(AuthLevel::Judge),
        "contestant" => Ok(AuthLevel::Contestant),
        _ => Err(ErrorBadRequest("Unknown auth level"))
    }
}

#[derive(PartialEq, Eq, PartialOrd, Ord, Debug)]
pub enum AuthLevel{
    Admin,
    Judge,
    Contestant
}

pub fn get_min_auth_level(method: String, path: String) -> AuthLevel {
    if ADMIN_REQUESTS.iter().any(|(m, p)| method == *m && *p == path) {
        return AuthLevel::Admin;
    };
    if JUDGE_REQUESTS.iter().any(|(m,p)| method == *m && *p == path) {
        return AuthLevel::Judge;
    };
    AuthLevel::Contestant
}

async fn authorization_check(req: ServiceRequest, next: Next<impl MessageBody>) -> Result<ServiceResponse<impl MessageBody>, Error> {
    let pool = req
        .app_data::<web::Data<MySqlPool>>()
        .ok_or_else(|| ErrorBadRequest("Database pool not found"))?;
    let cookie = req.cookie("Token");
    let mut token_to_send_back = String::from("");
    if cookie.is_none() {
        if req.method() != Method::POST || (req.path() != "/login" && req.path() != "/register") {
            return Err(ErrorBadRequest("No token cookie found"));
        }
    } else {
        let cookie = cookie.unwrap();
        let token_check = check_token(cookie.to_string(), pool).await;
        if token_check.is_err() { return Err(ErrorBadRequest(token_check.unwrap_err())); };
        let (new_token, user) = token_check.unwrap();

        let min_auth_level = get_min_auth_level(req.method().to_string(), req.path().to_string());
        let user_auth_level = string_to_auth_level(&user.ROLE)?;
        if min_auth_level > user_auth_level { return Err(ErrorBadRequest("No access to this path")); };

        token_to_send_back = new_token;
    }


    // invoke the wrapped middleware or service
    let mut res = next.call(req).await?;

    let cookie = Cookie::build("Token", token_to_send_back)
        .path("/") // Set the path for the cookie
        .http_only(true) // Ensure the cookie is HTTP-only
        .finish();
    res.response_mut().add_cookie(&cookie).map_err(Error::from)?;

    Ok(res)
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    if std::env::var_os("RUST_LOG").is_none() {
        std::env::set_var("RUST_LOG", "actix_web=info");
    }
    dotenv().ok();
    env_logger::init();

    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let pool = match MySqlPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
    {
        Ok(pool) => {
            println!("Connection to the database is successfull!");
            pool
        }
        Err(err) => {
            println!("Failed to connect to the database: {:?}", err);
            std::process::exit(1);
        }
    };

    println!("Server started successfully under http://localhost:8000");


    let bind_address = if cfg!(debug_assertions) {
        "127.0.0.1"
    } else {
        "0.0.0.0"
    };

    HttpServer::new(move || {
        let cors = Cors::default()
            .allowed_methods(vec!["GET", "POST", "PATCH", "DELETE"])
            .allowed_headers(vec![
                header::CONTENT_TYPE,
                header::AUTHORIZATION,
                header::ACCEPT,
            ])
            .supports_credentials();
        App::new()
            .app_data(web::Data::new(pool.clone()))
            .wrap(middleware::from_fn(authorization_check))
            .configure(api::service::config)
            .wrap(cors)
            .wrap(Logger::default())
    })
        .bind((bind_address, 8000))?
        .run()
        .await
}