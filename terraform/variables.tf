variable "credentials" {
  description = "Credentials"
}

variable "project" {
  description = "Project"
}

variable "region" {
  description = "Project Region"
  default     = "SOUTHAMERICA-EAST1"
}

variable "location" {
  description = "Project Location"
  default     = "SOUTHAMERICA-EAST1"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "aneel-bucket"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}

variable "service_account" {
  description = "Service Account for Data Transfer"
}