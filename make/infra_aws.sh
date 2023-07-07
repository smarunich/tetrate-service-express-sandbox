#!/usr/bin/env bash
set -ex

export ROOT_DIR="$( cd -- "$(dirname "${0}")" >/dev/null 2>&1 ; pwd -P )" ;
source ${ROOT_DIR}/variables.sh ;

export ACTION=${1} ;

if [[ ${ACTION} = "deploy" ]]; then
  cd "${ROOT_DIR}/../infra/aws";
  export AWS_K8S_CLUSTERS=$(echo ${TFVARS} | jq -c ".k8s_clusters.aws");
  export AWS_K8S_CLUSTERS_COUNT=$(echo ${AWS_K8S_CLUSTERS} | jq length);
  for i in $(seq 0 ${AWS_K8S_CLUSTERS_COUNT}); 
	do
		echo $AWS_K8S_CLUSTERS;
    cluster_name=$(echo $AWS_K8S_CLUSTERS | jq -cr '.['$i'].name');
    region=$(echo $AWS_K8S_CLUSTERS | jq -cr '.['$i'].region');
		k8s_version=$(echo $AWS_K8S_CLUSTERS | jq -cr '.['$i'].version');
		terraform workspace new aws-$i-$region || true; 
		terraform workspace select aws-$i-$region; 
		terraform init; 
		terraform apply ${TERRAFORM_APPLY_ARGS} -var-file="../../terraform.tfvars.json" \
			-var=cluster_name=$cluster_name\
			-var=cluster_id=$i\
			-var=region=$region\
			-var=k8s_version=$k8s_version;
		terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-aws-$i-$cluster_name.json;
		terraform workspace select default; 
  done;
	cd "../..";
fi

if [[ ${ACTION} = "destroy" ]]; then
  cd "${ROOT_DIR}/../infra/aws";
  export AWS_K8S_CLUSTERS=$(echo ${TFVARS} | jq -c ".k8s_clusters.aws");
  export AWS_K8S_CLUSTERS_COUNT=$(echo ${AWS_K8S_CLUSTERS} | jq length);
  for i in $(seq 0 ${AWS_K8S_CLUSTERS_COUNT}); 
	do
		echo $AWS_K8S_CLUSTERS;
    cluster_name=$(echo $AWS_K8S_CLUSTERS | jq -cr '.['$i'].name');
    region=$(echo $AWS_K8S_CLUSTERS | jq -cr '.['$i'].region');
		k8s_version=$(echo $AWS_K8S_CLUSTERS | jq -cr '.['$i'].version');
		terraform workspace select aws-$i-$region; 
		terraform destroy ${TERRAFORM_DESTROY_ARGS} -var-file="../../terraform.tfvars.json" \
			-var=cluster_name=$cluster_name\
			-var=cluster_id=$i\
			-var=region=$region\
			-var=k8s_version=$k8s_version;
		terraform workspace select default; 
		terraform workspace delete aws-$i-$region;
  done;
	cd "../..";
fi