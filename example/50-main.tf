module "network" {
  source = "github.com/Yunsang-Jeong/terraform-aws-network?ref=v1.0.0"

  vpc_cidr_block = "10.0.0.0/16"
  create_igw     = true
  subnets = [
    {
      identifier            = "public-a"
      name_tag_postfix      = "pub-a"
      availability_zone     = "ap-northeast-2a"
      cidr_block            = "10.0.104.0/24"
      enable_route_with_igw = true
      create_nat            = true
    },
    {
      identifier            = "public-c"
      name_tag_postfix      = "pub-c"
      availability_zone     = "ap-northeast-2c"
      cidr_block            = "10.0.105.0/24"
      enable_route_with_igw = true
    },
    {
      identifier            = "private-web-a"
      name_tag_postfix      = "pri-web-a"
      availability_zone     = "ap-northeast-2a"
      cidr_block            = "10.0.106.0/24"
      enable_route_with_nat = true
    },
    {
      identifier            = "private-web-c"
      name_tag_postfix      = "pri-web-c"
      availability_zone     = "ap-northeast-2c"
      cidr_block            = "10.0.107.0/24"
      enable_route_with_nat = true
    },
    {
      identifier            = "private-was-a"
      name_tag_postfix      = "pri-was-a"
      availability_zone     = "ap-northeast-2a"
      cidr_block            = "10.0.108.0/24"
      enable_route_with_nat = true
    },
    {
      identifier            = "private-was-c"
      name_tag_postfix      = "pri-was-c"
      availability_zone     = "ap-northeast-2c"
      cidr_block            = "10.0.109.0/24"
      enable_route_with_nat = true
    },
    {
      identifier        = "private-db-a"
      name_tag_postfix  = "pri-db-a"
      availability_zone = "ap-northeast-2a"
      cidr_block        = "10.0.110.0/24"
    },
    {
      identifier        = "private-db-c"
      name_tag_postfix  = "pri-db-c"
      availability_zone = "ap-northeast-2c"
      cidr_block        = "10.0.111.0/24"
    }
  ]
  name_tag_convention = local.name_tag_convention
}