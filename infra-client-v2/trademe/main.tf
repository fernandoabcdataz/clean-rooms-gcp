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

resource "google_project_service" "enable_analyticshub_api" {
  project = var.project_id
  service = "analyticshub.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}

resource "google_project_service" "enable_cloudresourcemanager_api" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"

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

resource "google_storage_bucket_object" "trademe_customers_file" {
  name         = "trademe_customers.csv"
  source       = "../../data-generator-v2/trademe_customers.csv"
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
    source_uris   = ["gs://${google_storage_bucket.data_bucket.name}/${google_storage_bucket_object.trademe_customers_file.name}"]
    csv_options {
      quote             = "\""
      skip_leading_rows = 1
    }
  }
}

/*
resource "google_project_iam_member" "bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:your-service-account@your-project.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "bigquery_dataowner" {
  project = var.project_id
  role    = "roles/bigquery.dataOwner"
  member  = "serviceAccount:your-service-account@your-project.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "bigquery_jobuser" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:your-service-account@your-project.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "bigquery_dataviewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:your-service-account@your-project.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:your-service-account@your-project.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "storage_objectadmin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:your-service-account@your-project.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "storage_objectviewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:your-service-account@your-project.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "analyticshub_viewer" {
  project = var.project_id
  role    = "roles/analyticshub.viewer"
  member  = "serviceAccount:your-service-account@your-project.iam.gserviceaccount.com"
}
*/