# -----------------------------------------------------------------------------
# Object storage: R2 bucket for server backups, with the R2 Data Catalog
# (Apache Iceberg) enabled. Not bound to the MCP Worker: backups stay private.
# -----------------------------------------------------------------------------

variable "backup_bucket_name" {
  description = "R2 bucket for server backups"
  type        = string
  default     = "warnetech-server-backup"
}

resource "cloudflare_r2_bucket" "server_backup" {
  account_id = var.cloudflare_account_id
  name       = var.backup_bucket_name
}

resource "cloudflare_r2_data_catalog" "server_backup" {
  account_id  = var.cloudflare_account_id
  bucket_name = cloudflare_r2_bucket.server_backup.name
}

output "backup_s3_endpoint" {
  description = "R2 S3-compatible API endpoint for the backup bucket"
  value       = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com/${cloudflare_r2_bucket.server_backup.name}"
}

output "backup_catalog_uri" {
  description = "Iceberg REST catalog URI for the backup bucket"
  value       = "https://catalog.cloudflarestorage.com/${var.cloudflare_account_id}/${cloudflare_r2_bucket.server_backup.name}"
}

output "backup_warehouse" {
  description = "Iceberg warehouse name for the backup bucket"
  value       = "${var.cloudflare_account_id}_${cloudflare_r2_bucket.server_backup.name}"
}
