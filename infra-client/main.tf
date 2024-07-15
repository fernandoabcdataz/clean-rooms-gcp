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

resource "google_storage_bucket_object" "customers_file" {
  name         = "customers.csv"
  source       = "../data-generator/customers.csv"
  content_type = "text/plain"
  bucket       = google_storage_bucket.data_bucket.id
}

resource "google_storage_bucket_object" "calls_file" {
  name         = "calls.csv"
  source       = "../data-generator/calls.csv"
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
    source_uris   = ["gs://${google_storage_bucket.data_bucket.name}/${google_storage_bucket_object.customers_file.name}"]
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
    source_uris   = ["gs://${google_storage_bucket.data_bucket.name}/${google_storage_bucket_object.calls_file.name}"]
    csv_options {
      quote             = "'"
      skip_leading_rows = 1
    }
  }
}

resource "google_bigquery_table" "calls_about_products_view" {
  dataset_id = google_bigquery_dataset.customers_dataset.dataset_id
  table_id   = "calls_about_products"
  deletion_protection = false

  view {
    use_legacy_sql = false
    query = <<SQLQUERY
      SELECT
        cust.email,
        calls.product,
        calls.call_datetime
      FROM
        `${var.project_id}.client_customer.customers` cust
      LEFT JOIN
        `${var.project_id}.client_customer.calls` calls
      ON
        cust.id = calls.customer_id
      WHERE calls.customer_id is not null
    SQLQUERY
  }

  depends_on = [
    google_bigquery_table.calls_table
  ]
}

resource "google_bigquery_analytics_hub_data_exchange" "data_exchange" {
  location         = google_bigquery_dataset.customers_dataset.location
  data_exchange_id = "clean_room_poc"
  display_name     = "Clean Room Proof of Concept"
  description      = "example data exchange"
}

resource "google_bigquery_analytics_hub_listing" "listing" {
  location         = google_bigquery_dataset.customers_dataset.location
  data_exchange_id = google_bigquery_analytics_hub_data_exchange.data_exchange.data_exchange_id
  listing_id       = "customer_calls_about_products"
  display_name     = "Customer Calls About Products"
  description      = "Hashed customer identifier for each call received about a product and when the call occured"

  bigquery_dataset {
    dataset = google_bigquery_dataset.customers_dataset.id
  }
}

resource "google_bigquery_dataset" "raw_data_exchange" {
  dataset_id    = "raw_data_exchange"
  friendly_name = "data to exchange"
  description   = "example data exchange"
  location      = google_bigquery_dataset.customers_dataset.location
}

resource "google_bigquery_table" "calls_about_products_view_raw" {
  dataset_id = google_bigquery_dataset.raw_data_exchange.dataset_id
  table_id   = "calls_about_products"
  deletion_protection = false

  view {
    use_legacy_sql = false
    query = <<SQLQUERY
      select
        sha256(email) hashedEmail,
        product,
        call_datetime
      from
        `client_customer.calls_about_products`
    SQLQUERY
  }

  depends_on = [
    google_bigquery_table.calls_about_products_view
  ]
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
  job_id = "load_calls_about_products_table"
  
  query {
    query = <<SQLQUERY
      INSERT INTO `${google_bigquery_dataset.raw_data_exchange.dataset_id}.${google_bigquery_table.calls_about_products_table.table_id}`
      SELECT
        md5(email) AS hashedEmail,
        product,
        call_datetime
      FROM
        `client_customer.calls_about_products`
    SQLQUERY

    use_legacy_sql = false
  }

  depends_on = [
    google_bigquery_table.calls_about_products_table,
    google_bigquery_table.calls_about_products_view
  ]
}
