resource "random_string" "unique_name" {
  length  = 3
  numeric = false
  special = false
  upper   = false
}
