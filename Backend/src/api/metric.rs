use actix_web::web;
use sqlx::MySqlPool;
use uuid::Uuid;
use crate::model::metric::{CreateMetric, Metric};

pub async fn create_metric(metric: CreateMetric, db: &web::Data<MySqlPool>) -> Result<Metric,String> {
    let metric_id = Uuid::new_v4();
    let metric_query =
        sqlx::query("INSERT INTO METRIC (ID, TIME, TIMEUNIT, LENGTH, LENGTHUNIT, WEIGHT, WEIGHTUNIT, AMOUNT)
                                              VALUES (?, ?, ?, ?, ?, ?, ?, ?)")
            .bind(metric_id.to_string())
            .bind(metric.TIME)
            .bind(metric.TIMEUNIT.clone().or(Some("S".to_string())))
            .bind(metric.LENGTH)
            .bind(metric.LENGTHUNIT.clone().or(Some("M".to_string())))
            .bind(metric.WEIGHT)
            .bind(metric.WEIGHTUNIT.clone().or(Some("KG".to_string())))
            .bind(metric.AMOUNT)
            .execute(db.as_ref())
            .await;

    match metric_query {
        Ok(_) => Ok(Metric {
                ID: metric_id.to_string(),
                TIME : metric.TIME,
                TIMEUNIT : metric.TIMEUNIT.or(Some("S".to_string())),
                LENGTH : metric.LENGTH,
                LENGTHUNIT : metric.LENGTHUNIT.or(Some("M".to_string())),
                WEIGHT : metric.WEIGHT,
                WEIGHTUNIT : metric.WEIGHTUNIT.or(Some("KG".to_string())),
                AMOUNT : metric.AMOUNT
            })
        ,
        Err(e) => Err(e.to_string())
    }
}