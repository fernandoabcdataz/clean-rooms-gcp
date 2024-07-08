/*resource "google_project" "clean_room_client" {
    name        = "Clean Room Client"
    project_id  = "clean-room-client"

}*/

/* pointless because the api can't be enable without this API being enabled*/
resource "google_project_service" "enable_service_usage_api" {
  project = "clean-room-client"
  service = "serviceusage.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}

resource "google_project_service" "enable_bigquery_api" {
  project = "clean-room-client"
  service = "bigquery.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}

resource "google_bigquery_dataset" "customers_dataset" {
    dataset_id                  = "client_customer"
    description                 = "The clients customer list"
    location                    = "Australia-SouthEast1"

    depends_on = [
    google_project_service.enable_bigquery_api
  ]
}

resource "google_storage_bucket" "data_bucket" {
  name          = "clean_room_raw_data"
  location      = google_bigquery_dataset.customers_dataset.location
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
  table_id    = "customers"

  # Define schema for your table columns (required)
  schema = <<SCHEMA
  id  INTEGER,
  NAME  string,
  ADDRESS string
  # Add more fields and data types as needed
  SCHEMA

  # Reference the GCS location of your CSV file
    external_data_configuration {
        source_format = "CSV"  # Specify the file format
        source_uris = [ "${google_storage_bucket.data_bucket.self_link}/${google_storage_bucket_object.customers_file.name}" ]  # Reference the GCS bucket
        # Optional: Configure how to handle leading rows (headers)
        csv_options {
            quote = "'"
            skip_leading_rows = 1  # Skip first row (assuming header)
        }
    }
}

