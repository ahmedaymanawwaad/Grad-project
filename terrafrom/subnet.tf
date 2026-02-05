resource "aws_subnet" "public_subnet-1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name                                   = "public-subnet-1"
    "kubernetes.io/role/elb"               = "1"
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "public_subnet-2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = {
    Name                                   = "public-subnet-2"
    "kubernetes.io/role/elb"               = "1"
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "private_subnet-1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name                                   = "private-subnet-1"
    "kubernetes.io/role/internal-elb"      = "1"
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "private_subnet-2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-central-1b"
  tags = {
    Name                                   = "private-subnet-2"
    "kubernetes.io/role/internal-elb"      = "1"
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
  }
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet-1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet-2.id
  route_table_id = aws_route_table.public_rt.id
}



resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet-1.id
  route_table_id = aws_route_table.private_rt_1.id
}



resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet-2.id
  route_table_id = aws_route_table.private_rt_2.id
}
