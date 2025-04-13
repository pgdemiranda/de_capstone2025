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
  region      = var.region
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

# Criando múltiplos datasets
resource "google_bigquery_dataset" "raw_data" {
  dataset_id = "raw_data"
  location   = var.location
  description = "Dataset para dados brutos"
}

# resource "google_bigquery_dataset" "staging" {
#   dataset_id = "staging"
#   location   = var.location
#   description = "Dataset para dados em estágio"
# }
# 
# resource "google_bigquery_dataset" "dimensions" {
#   dataset_id = "dimensions"
#   location   = var.location
#   description = "Dataset para tabelas de dimensões"
# }
# 
# resource "google_bigquery_dataset" "facts" {
#   dataset_id = "facts"
#   location   = var.location
#   description = "Dataset para tabelas de fatos"
# }

resource "google_bigquery_table" "componente_tarifarias_raw" {
  dataset_id = google_bigquery_dataset.raw_data.dataset_id
  table_id   = "componente_tarifarias"

  schema = file("${path.module}/schemas/componente_tarifarias.json")
}

# resource "google_bigquery_table" "componente_tarifarias_staging" {
#   dataset_id = google_bigquery_dataset.staging.dataset_id
#   table_id   = "componente_tarifarias_processed"
# 
#   schema = file("${path.module}/schemas/componente_tarifarias.json")
# }