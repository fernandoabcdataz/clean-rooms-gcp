terraform {
    required_providers {
      google = {
        source  = "hashicorp/google"
        version = "5.36.0"
      }
    }
}

provider "google" {
    project     = "clean-room-client"
    region      = "australia-southeast1"
    credentials = "../clean-room-client-credentials.json"
}