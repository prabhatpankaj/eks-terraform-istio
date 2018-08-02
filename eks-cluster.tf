resource "aws_eks_cluster" "eksproject" {
  name     = "${var.cluster-name}"
  role_arn = "${aws_iam_role.eksproject-cluster.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.eksproject-cluster.id}"]
    subnet_ids         = ["${module.vpc.public_subnets}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eksproject-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eksproject-cluster-AmazonEKSServicePolicy",
  ]
}

