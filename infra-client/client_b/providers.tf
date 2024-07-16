terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.36.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = "australia-southeast1"
  credentials = "/.../.gcloud/service-account-key-2.json"
}