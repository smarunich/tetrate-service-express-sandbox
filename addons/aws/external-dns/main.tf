data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../../infra/${var.k8s_cluster["cloud"]}/terraform.tfstate.d/${var.k8s_cluster["cloud"]}-${var.cluster_id}-${var.region}/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s_auth" {
  backend = "local"
  config = {
    path = "../../../infra/${var.k8s_cluster["cloud"]}/k8s_auth/terraform.tfstate.d/${var.k8s_cluster["cloud"]}-${var.cluster_id}-${var.region}/terraform.tfstate"
  }
}

module "external_dns" {
  source                     = "../../../modules/addons/aws/external-dns"
  name_prefix                = "${var.name_prefix}-${var.cluster_id}"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  oidc_provider_arn          = data.terraform_remote_state.infra.outputs.oidc_provider_arn
  cluster_oidc_issuer_url    = data.terraform_remote_state.infra.outputs.cluster_oidc_issuer_url
  cluster_oidc_id            = trimprefix (data.terraform_remote_state.infra.outputs.cluster_oidc_issuer_url, "https://")
  # vpc_id                     = data.terraform_remote_state.infra.outputs.vpc_id
  region                     = var.region
  tags                       = local.default_tags
  dns_zone                   = var.external_dns_aws_dns_zone
  # sources                    = var.external_dns_sources
  # annotation_filter          = var.external_dns_annotation_filter
  # label_filter               = var.external_dns_label_filter
  # interval                   = var.external_dns_interval
  output_path                = var.output_path
}