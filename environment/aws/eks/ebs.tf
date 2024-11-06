data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa_ebs_csi" {
  count = local.should_create ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${var.cluster.name}"
  provider_url                  = module.eyelevel_eks[0].oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  count = local.should_create ? 1 : 0

  depends_on               = [module.eyelevel_eks]

  cluster_name             = var.cluster.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = module.irsa_ebs_csi[0].iam_role_arn
}