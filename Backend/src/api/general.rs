use actix_web::web;
use serde::{Deserialize, Serialize};
use sqlx::MySqlPool;

#[derive(Debug, Deserialize, Serialize, sqlx::FromRow)]
pub struct FieldWithValue {
    pub name: &'static str,
    pub value: String,
}

pub async fn optional_update_handler(table_name: &'static str,
                                     fields: Vec<FieldWithValue>,where_key: String,
                                        db: &MySqlPool
) {

}
pub async fn update_table_handler(table_name: &'static str,
                                  fields: Vec<FieldWithValue>,
                                  where_key: String,
                                  db: &MySqlPool
)
                                  -> Result<Vec<FieldWithValue>, String> {
    if fields.is_empty() { return Err(String::from("No fields to update")); };

    let mut query = String::with_capacity(64);
    query += format!("UPDATE {} SET ", table_name).as_str();
    for field in &fields {
        query += format!("{} = \"{}\", ", field.name, field.value).as_str();
    }
    query.truncate(query.len().saturating_sub(2));
    query += format!(" WHERE {where_key}").as_str();

    let query = sqlx::query(&query).execute(db).await;

    match query {
        Ok(rows) => Ok(fields),
        Err(err) => Err(err.to_string())
    }
}
