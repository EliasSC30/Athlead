use actix_web::web;
use sqlx::MySqlPool;
use uuid::Uuid;
use crate::model::metric::{CreateMetric, Metric};

pub async fn create_metric(metric: CreateMetric, db: &web::Data<MySqlPool>) -> Result<Metric,String> {
    let metric_id = Uuid::new_v4();
    let metric_query =
        sqlx::query("INSERT INTO METRIC (ID,VALUE,UNIT)
                                              VALUES (?, ?, ?)")
            .bind(metric_id.to_string())
            .bind(metric.value.clone())
            .bind(metric.unit.clone())
            .execute(db.as_ref())
            .await;

    match metric_query {
        Ok(_) => Ok(Metric {
                id: metric_id.to_string(),
                value: metric.value,
                unit: metric.unit
            })
        ,
        Err(e) => Err(e.to_string())
    }
}