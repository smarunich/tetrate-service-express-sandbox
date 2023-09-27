variable "name_prefix" {
}

variable "cluster_name" {
}

variable "cloud" {
}

variable "jumpbox_host" {
}

variable "jumpbox_username" {
}

variable "jumpbox_pkey" {
}

variable "tetrate_version" {
}

variable "tetrate_helm_repository" {
}

variable "tetrate_helm_repository_username" {
}

variable "tetrate_helm_repository_password" {
}

variable "tetrate_managementplane_hostname" {
}

variable "tetrate_password" {
}

variable "registry" {
}

variable "k8s_host" {
}

variable "k8s_cluster_ca_certificate" {
}

variable "k8s_client_token" {
}

variable "output_path" {
}

variable "external_dns_aws_dns_zone" {
}

variable "service_account_name" {
    type = string
    default = "route53-controller"
    description = "Name of Service Account in kubernetes cluster."
}