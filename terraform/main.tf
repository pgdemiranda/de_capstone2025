terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.27.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = var.location
}

resource "google_storage_bucket" "componentes-tarifarias" {
  name          = var.gcs_bucket_name
  location      = var.location
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }

  versioning {
    enabled = true
  }
}

resource "google_bigquery_dataset" "raw_data" {
  dataset_id = "raw_data"
  location   = var.location
  description = "Dataset for raw data extracted"
}

resource "google_bigquery_table" "componente_tarifarias_raw" {
  dataset_id = google_bigquery_dataset.raw_data.dataset_id
  table_id   = "componente_tarifarias"

  schema = file("${path.module}/schemas/componente_tarifarias.json")
}