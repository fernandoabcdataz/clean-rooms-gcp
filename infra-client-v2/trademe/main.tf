/* Uncomment this if you need to create a project
resource "google_project" "clean_room_client" {
    name        = "Clean Room Client"
    project_id  = var.project_id
}
*/

resource "google_project_service" "enable_service_usage_api" {
  project = var.project_id
  service = "serviceusage.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}

resource "google_project_service" "enable_bigquery_api" {
  project = var.project_id
  service = "bigquery.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}

resource "google_bigquery_dataset" "customers_dataset" {
  dataset_id  = "client_customer"
  description = "The clients customer list"
  location    = "australia-southeast1"

  depends_on = [
    google_project_service.enable_bigquery_api
  ]
}

resource "google_storage_bucket" "data_bucket" {
  name     = "clean_room_raw_data"
  location = google_bigquery_dataset.customers_dataset.location
}

resource "google_storage_bucket_object" "iag_customers_file" {
  name         = "iag_customers.csv"
  source       = "../../data-generator-v2/iag_customers.csv"
  content_type = "text/plain"
  bucket       = google_storage_bucket.data_bucket.id
}

resource "google_storage_bucket_object" "iag_calls_file" {
  name         = "iag_calls.csv"
  source       = "../../data-generator-v2/iag_calls.csv"
  content_type = "text/plain"
  bucket       = google_storage_bucket.data_bucket.id
}

resource "google_bigquery_table" "customer_table" {
  dataset_id = google_bigquery_dataset.customers_dataset.dataset_id
  table_id   = "customers"

  deletion_protection = false

  schema = <<SCHEMA
    [
    {
      "name": "id",
      "type": "INTEGER"
    },
    {
      "name": "name",
      "type": "STRING"
    },
    {
      "name": "address",
      "type": "STRING"
    },
    {
      "name": "email",
      "type": "STRING"
    }
    ]
  SCHEMA

  external_data_configuration {
    source_format = "CSV"
    autodetect    = true
    source_uris   = ["gs://${google_storage_bucket.data_bucket.name}/${google_storage_bucket_object.iag_customers_file.name}"]
    csv_options {
      quote             = "\""
      skip_leading_rows = 1
    }
  }
}

resource "google_bigquery_table" "calls_table" {
  dataset_id = google_bigquery_dataset.customers_dataset.dataset_id
  table_id   = "calls"

  deletion_protection = false

  schema = <<SCHEMA
    [
    {
      "name": "id",
      "type": "STRING"
    },
    {
      "name": "customer_id",
      "type": "INTEGER"
    },
    {
      "name": "call_datetime",
      "type": "DATETIME"
    },
    {
      "name": "product",
      "type": "STRING"
    }
    ]
  SCHEMA

  external_data_configuration {
    source_format = "CSV"
    autodetect    = true
    source_uris   = ["gs://${google_storage_bucket.data_bucket.name}/${google_storage_bucket_object.iag_calls_file.name}"]
    csv_options {
      quote             = "'"
      skip_leading_rows = 1
    }
  }
}

resource "google_bigquery_dataset" "raw_data_exchange" {
  dataset_id    = "raw_data_exchange"
  friendly_name = "data to exchange"
  description   = "example data exchange"
  location      = google_bigquery_dataset.customers_dataset.location
}

resource "google_bigquery_table" "calls_about_products_table" {
  dataset_id = google_bigquery_dataset.raw_data_exchange.dataset_id
  table_id   = "calls_about_products_table"
  deletion_protection = false

  schema = <<SCHEMA
  [
    {
      "name": "hashedEmail",
      "type": "STRING"
    },
    {
      "name": "product",
      "type": "STRING"
    },
    {
      "name": "call_datetime",
      "type": "DATETIME"
    }
  ]
  SCHEMA
}

resource "google_bigquery_job" "load_calls_about_products_table" {
  job_id = "load_calls_about_products_table_${uuid()}"

  query {
    query = <<SQLQUERY
      INSERT INTO `${google_bigquery_dataset.raw_data_exchange.dataset_id}.${google_bigquery_table.calls_about_products_table.table_id}`
      SELECT
        md5(cust.email) AS hashed_email,
        calls.product,
        calls.call_datetime
      FROM
        `${var.project_id}.client_customer.customers` cust
      LEFT JOIN
        `${var.project_id}.client_customer.calls` calls
      ON
        cust.id = calls.customer_id
      WHERE calls.customer_id IS NOT NULL
    SQLQUERY

    use_legacy_sql = false
  }

  lifecycle {
    ignore_changes = [job_id]
  }

  depends_on = [
    google_bigquery_table.calls_about_products_table,
    google_bigquery_table.calls_table
  ]
}
