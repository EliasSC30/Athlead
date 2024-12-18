
mod api;
mod model;

use std::ops::Add;
use std::time;
use actix_cors::Cors;
use actix_web::middleware::Logger;
use actix_web::{cookie, http::header, web, App, HttpMessage, HttpRequest, HttpResponse, HttpServer};
use dotenv::dotenv;
use sqlx::mysql::{MySqlPool, MySqlPoolOptions};
use actix_web::middleware::{self, Next};
use actix_web::{dev::{ServiceRequest, ServiceResponse},web::Path, Error, cookie::Cookie, body::MessageBody};
use actix_web::cookie::Expiration;
use actix_web::error::{ErrorBadGateway, ErrorBadRequest};
use actix_web::http::Method;
use crate::api::logon::check_token;
use crate::model::person::Person;

const ADMIN_REQUESTS: [(&'static str, &'static str);1] = [("GET", "/details")];
const JUDGE_REQUESTS: [(&'static str, &'static str);1] = [("GET", "/sportfests")];

pub fn string_to_auth_level(role: &String) -> Result<AuthLevel, Error> {
    println!("{}",role);
    match role.as_str().to_lowercase().as_str() {
        "admin" => Ok(AuthLevel::Admin),
        "judge" => Ok(AuthLevel::Judge),
        "contestant" => Ok(AuthLevel::Contestant),
        _ => Err(ErrorBadRequest("Unknown auth level"))
    }
}

#[derive(PartialEq, Eq, PartialOrd, Ord, Debug)]
pub enum AuthLevel{
    Contestant,
    Judge,
    Admin,
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

fn req_needs_cookie(req: &ServiceRequest) -> bool {
    if req.method() == Method::POST {
        return req.path() != "/login" && req.path() != "/register";
    };
    if req.method() == Method::GET {
        return req.path() != "/health";
    };

    true
}

async fn authorization_check(req: ServiceRequest, next: Next<impl MessageBody>) -> Result<ServiceResponse<impl MessageBody>, Error> {
    let pool = req
        .app_data::<web::Data<MySqlPool>>()
        .ok_or_else(|| ErrorBadRequest("Database pool not found"))?;
    let cookie = req.cookie("Token");
    let mut token_to_send_back = String::from("");
    let mut request_sender: Option<Person> = None;

    if req_needs_cookie(&req) {
        if cookie.is_none() {
            return Err(ErrorBadGateway("No Token send"));
        } else {
            let cookie = cookie.unwrap();
            let token_check = check_token(cookie.to_string(), pool).await;
            if token_check.is_ok() {
                let (new_token, user) = token_check.unwrap();

                let min_auth_level = get_min_auth_level(req.method().to_string(), req.path().to_string());
                let user_auth_level = string_to_auth_level(&user.ROLE)?;
                if min_auth_level > user_auth_level { return Err(ErrorBadRequest("No access to this path")); };

                token_to_send_back = new_token;
                request_sender = Some(user);
            } else {
                if req.path() != "/loggedin" { return Err(ErrorBadRequest("Invalid Token")); };
            }
        };
    }

    if let Some(request_sender) = request_sender {
        req.extensions_mut().insert(request_sender);
    }

    // invoke the wrapped middleware or service
    let mut res = next.call(req).await?;

    if !token_to_send_back.is_empty() {
        let duration = cookie::time::Duration::days(9999);
        let expire_date = cookie::time::OffsetDateTime::now_utc().add(duration);
        let cookie = Cookie::build("Token", token_to_send_back)
            .path("/")
            .http_only(true)
            .expires(expire_date)
            .finish();
        res.response_mut().add_cookie(&cookie).map_err(Error::from)?;
    }

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