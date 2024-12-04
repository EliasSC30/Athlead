use actix_web::web;
use uuid::Uuid;
use crate::AppState;
use crate::model::metric::{CreateMetric, Metric};

pub async fn create_metric(metric: CreateMetric, data: &web::Data<AppState>) -> Option<Metric> {
    let metric_id = Uuid::new_v4();
    let metric_query =
        sqlx::query("INSERT INTO METRIC (ID, TIME, TIMEUNIT, LENGTH, LENGTHUNIT, WEIGHT, WEIGHTUNIT, AMOUNT)
                                              VALUES (?, ?, ?, ?, ?, ?, ?, ?)")
            .bind(metric_id.to_string())
            .bind(metric.TIME)
            .bind(metric.TIMEUNIT.clone().or(Some("SECONDS".to_string())))
            .bind(metric.LENGTH)
            .bind(metric.LENGTHUNIT.clone().or(Some("METERS".to_string())))
            .bind(metric.WEIGHT)
            .bind(metric.WEIGHTUNIT.clone().or(Some("KILOGRAMS".to_string())))
            .bind(metric.AMOUNT)
            .execute(&data.db)
            .await;

    match metric_query {
        Ok(_) => {
            Some(Metric {
                ID: metric_id.to_string(),
                TIME : metric.TIME,
                TIMEUNIT : metric.TIMEUNIT.or(Some("SECONDS".to_string())),
                LENGTH : metric.LENGTH,
                LENGTHUNIT : metric.LENGTHUNIT.or(Some("METERS".to_string())),
                WEIGHT : metric.WEIGHT,
                WEIGHTUNIT : metric.WEIGHTUNIT.or(Some("KILOGRAMS".to_string())),
                AMOUNT : metric.AMOUNT
            })
        }
        Err(_) => None
    }
}