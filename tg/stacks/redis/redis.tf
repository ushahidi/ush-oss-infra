resource "aws_security_group" "redis" {
  name = "redis-${var.product}-${var.environment}"
  description = "Allow necessary traffic to redis"
  vpc_id = data.aws_vpc.main.id

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    ush-environment = "${var.environment}"
    ush-product = "${var.product}"
    ush-component = "redis"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name = "${var.product}-${var.environment}"
  subnet_ids = data.aws_subnet.main.*.id
}

resource "aws_elasticache_parameter_group" "default" {
  name = "params-${var.product}-${var.environment}"
  family = "redis${var.redis_version}"

  # To do configure params
  # parameter {
  #   name  = "activerehashing"
  #   value = "yes"
  # }
}

resource "aws_elasticache_cluster" "redis" {
  # Skipping product in name because 20 char max
  cluster_id           = "${var.environment}-redis"
  engine               = "redis"
  engine_version       = "${var.redis_minor_version}"
  port                 = 6379
  num_cache_nodes      = 1
  node_type            = "${var.cache_instance_type}"
  parameter_group_name = "${aws_elasticache_parameter_group.default.id}"
  subnet_group_name    = "${aws_elasticache_subnet_group.redis.id}"
  security_group_ids   = [ "${aws_security_group.redis.id}" ]

  apply_immediately = "${var.cache_apply_immediately}"

  tags = {
    ush-environment = "${var.environment}"
    ush-product = "${var.product}"
    ush-app = "${var.app}"
    ush-component = "redis"
  }
}

output "redis_address" { value = "${aws_elasticache_cluster.redis.cache_nodes.0.address}" }
output "redis_port" { value = "${aws_elasticache_cluster.redis.cache_nodes.0.port}" }

