variable "credentials" {
  description = "Credentials"
  default     = "../creds/gcp.json"
}

variable "project" {
  description = "Project"
  default     = "decapstone-455514"
}

variable "region" {
  description = "Project Region"
  default     = "SOUTHAMERICA-EAST1"
}

variable "location" {
  description = "Project Location"
  default     = "SOUTHAMERICA-EAST1"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "decapstone_dataset"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "aneel-bucket"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}