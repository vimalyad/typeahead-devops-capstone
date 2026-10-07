output "cluster_name" { value = aws_eks_cluster.lab.name }
output "vpc_id" { value = aws_vpc.lab.id }
output "subnet_ids" { value = aws_subnet.public[*].id }
output "node_group" { value = aws_eks_node_group.lab.node_group_name }
output "region" { value = var.region }
