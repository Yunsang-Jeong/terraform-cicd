resource "random_string" "pro" {
  length  = 4
  special = false
}

resource "random_string" "stg" {
  length  = 4
  special = false
}

locals {
  name_tag_convention = {
    region_shorten = "an2"
    project_name   = random_string.pro.result
    stage          = random_string.stg.result
  }
}