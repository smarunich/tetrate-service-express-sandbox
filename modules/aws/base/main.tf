data "aws_region" "current" {}

resource "aws_vpc" "tetrate" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags = merge(var.tags, {
    Name = "${var.name_prefix}_vpc"
  })
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "tetrate" {
  count                   = min(length(data.aws_availability_zones.available.names), var.min_az_count, var.max_az_count)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(var.cidr, 4, count.index)
  vpc_id                  = aws_vpc.tetrate.id
  map_public_ip_on_launch = "true"
  tags = merge(var.tags, {
  Name = "${var.name_prefix}_subnet_${data.aws_availability_zones.available.names[count.index]}", "kubernetes.io/role/elb" = 1, "kubernetes.io/role/internal-elb" = 1 })
}

resource "aws_internet_gateway" "tetrate" {
  vpc_id = aws_vpc.tetrate.id
  tags = merge(var.tags, {
    Name = "${var.name_prefix}_igw"
  })
}


resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.tetrate.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tetrate.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}_rt"
  })
}


resource "aws_route_table_association" "rta" {
  count          = min(length(data.aws_availability_zones.available.names), var.min_az_count, var.max_az_count)
  subnet_id      = element(aws_subnet.tetrate.*.id, count.index)
  route_table_id = aws_route_table.rt.id
}

resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

resource "aws_ecr_repository" "tetrate" {
  name = replace("tetrateecr${var.name_prefix}${random_string.random.result}", "-", "")
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}_ecr"
  })
}

data "aws_ecr_authorization_token" "token" {
}

resource "null_resource" "aws_cleanup" {
  triggers = {
    output_path = var.output_path
    name_prefix = var.name_prefix
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "sh ${self.triggers.output_path}/${self.triggers.name_prefix}-aws-cleanup.sh"
    on_failure = continue
  }

  depends_on = [aws_internet_gateway.tetrate, local_file.aws_cleanup]

}

resource "local_file" "aws_cleanup" {
  content = templatefile("${path.module}/aws_cleanup.sh.tmpl", {
    vpc_id        = aws_vpc.tetrate.id
    region        = data.aws_region.current.name
    registry_name = aws_ecr_repository.tetrate.name
    name_prefix   = substr("${var.name_prefix}",0,length("${var.name_prefix}")-5) # removes random generated string on suffix
  })
  filename        = "${var.output_path}/${var.name_prefix}-aws-cleanup.sh"
  file_permission = "0755"

  lifecycle {
    create_before_destroy = true
  }
}
