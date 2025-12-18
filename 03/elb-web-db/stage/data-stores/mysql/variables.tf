variable "dbuser" {
  description = "DB user name(ex: DBuser)"
  type       = string
  sensitive = true
}

variable "dbpassword" {
  description = "DB password(ex: dbpassword)"
  type       = string
  sensitive = true
}