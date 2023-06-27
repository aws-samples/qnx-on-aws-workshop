# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "= 5.0.0"

  name = local.name
  cidr = local.vpc.cidr
  azs  = slice(data.aws_availability_zones.region.names, 0, 2)
  public_subnets = [
    cidrsubnet(module.vpc.vpc_cidr_block, 8, 0),
    cidrsubnet(module.vpc.vpc_cidr_block, 8, 1),
  ]
  private_subnets = [
    cidrsubnet(module.vpc.vpc_cidr_block, 8, 10),
    cidrsubnet(module.vpc.vpc_cidr_block, 8, 11),
  ]

  map_public_ip_on_launch      = false
  public_subnet_ipv6_prefixes  = [0, 1]
  private_subnet_ipv6_prefixes = [10, 11]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = false
  create_flow_log_cloudwatch_iam_role  = false
  create_flow_log_cloudwatch_log_group = false
}

# ------------------------------------------------------------
# VPC Endpoint
# ------------------------------------------------------------

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "= 5.0.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = flatten([
        module.vpc.private_route_table_ids,
        module.vpc.public_route_table_ids
      ])
      tags = {
        Name = "${local.name}-s3-vpc-endpoint"
      }
    },

    secrets_manager = {
      service            = "secretsmanager"
      service_type       = "Interface"
      subnet_ids         = module.vpc.private_subnets
      security_group_ids = [aws_security_group.secrets_manager.id]
      tags = {
        Name = "${local.name}-secretsmanager-vpc-endpoint"
      }
    }

    cloudwatch_logs = {
      service            = "logs"
      service_type       = "Interface"
      subnet_ids         = module.vpc.private_subnets
      security_group_ids = [aws_security_group.cloudwatch_logs.id]
      tags = {
        Name = "${local.name}-cloudwatch-logs-vpc-endpoint"
      }
    }

  }
}

# ------------------------------------------------------------
# Security group for VPC endpoints
# ------------------------------------------------------------
resource "aws_security_group" "secrets_manager" {
  name_prefix = "${local.name}-secretsmanager-"
  description = "Secrets Manager SG for ${local.name}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  egress {
    description = "Egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "aws_security_group" "cloudwatch_logs" {
  name_prefix = "${local.name}-cloudwatch-logs-"
  description = "CloudWatch Logs SG for ${local.name}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  egress {
    description = "Egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}
