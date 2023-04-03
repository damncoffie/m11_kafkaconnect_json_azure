# Terraform
init:
	cd terraform && terraform init

apply:
	cd terraform && terraform apply


# Azure cluster login
az_login:
	az login

get_credentials:
	az aks get-credentials -g rg-kafkaconhm-westeurope -n aks-kafkaconhm-westeurope


# Install Confluent for Kubernetes
create_namespace:
	kubectl create namespace confluent

set_namespace:
	kubectl config set-context --current --namespace confluent

add_confluent_to_repo:
	helm repo add confluentinc https://packages.confluent.io/helm
	helm repo update

install_kube_confluent:
	helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes


# Create Docker image (image already pushed)
#build_and_tag:
#	cd connectors && docker build -t bobriashovm2/homework:10.0.2 -f Dockerfile .

#push_image:
#	cd connectors && docker push bobriashovm2/homework:10.0.2


# Install Confluent Platform
apply_platform:
	kubectl apply -f ./confluent-platform.yaml


apply_producer:
	kubectl apply -f ./producer-app-data.yaml


check_pods:
	kubectl get pods -o wide


# Port-forwarding
control_center:
	kubectl port-forward controlcenter-0 9021:9021

connect:
	kubectl port-forward connect-0 8083:8083


# Create connector
create_connector:
	curl -X POST -H "Content-Type: application/json" -d @/connectors/azure-source-cc-expedia.json http://localhost:8083/connectors


# Destroy infrastructure:
	cd terraform && terraform destroy
