# Kafka connect in Kubernetes

## Set up infrastructure with Terraform

Note: originally specified value `Standard_D2_v2` of parameter `vm_size` for `azurerm_kubernetes_cluster` has not enough resources for this task, so it was changed to `Standard_DS3_v2`.

- `terraform init`
- `terraform apply`

## Launch Confluent for Kubernetes

### Set up connection to cluster
- Login in Azure CLI:
  ```
  az login
  ```

- Get credentials for your cluster:
  ```
  az aks get-credentials -g rg-kafkaconhm-westeurope -n aks-kafkaconhm-westeurope
  ```

### Create a namespace

- Create the namespace to use:

  ```cmd
  kubectl create namespace confluent
  ```

  ![image](screenshots/3%20confluent%20create%20namespace.PNG)

- Set this namespace to default for your Kubernetes context:

  ```cmd
  kubectl config set-context --current --namespace confluent
  ```

  ![image](screenshots/4%20set%20context.PNG)

### Install Confluent for Kubernetes

- Add the Confluent for Kubernetes Helm repository:

  ```cmd
  helm repo add confluentinc https://packages.confluent.io/helm
  helm repo update
  ```
  ![image](screenshots/5%20helm%20repo%20add.PNG)
  ![image](screenshots/6%20helm%20repo%20update.PNG)


- Install Confluent for Kubernetes:

  ```cmd
  helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes
  ```
  ![image](screenshots/7%20helm%20upgrade.PNG)

## Create your own connector's image

Note: versions of `confluentinc/cp-server-connect-operator`, `confluentinc/kafka-connect-azure-blob-storage` and `confluentinc/kafka-connect-azure-blob-storage-source`, which were specified in Dockerfile originally, are not working properly together (connector never appears and never runs in Confluence center).  

Working combination in my case were `6.1.6.0`, and `latest` for latter respectively.

- Build and tag an image using provided Dockerfile

  ![image](screenshots/1%20docker%20build.PNG.png)

- Push image to your DockerHub repo:

  ![image](screenshots/2%20docker%20push.PNG)

- Use it in confluent-platform.yaml
```
my-azure-connector:1.0.0 --> bobriashovm2/homework:10.0.2
```

### Install Confluent Platform

- Install all Confluent Platform components:

  ```cmd
  kubectl apply -f ./confluent-platform.yaml
  ```

  ![image](screenshots/8%20apply%20confluent%20platforn.PNG)

- Install a sample producer app and topic:

  ```cmd
  kubectl apply -f ./producer-app-data.yaml
  ```

  ![image](screenshots/9%20apply%20producer%20app%20data.PNG)

- Check that everything is deployed:

  ```cmd
  kubectl get pods -o wide 
  ```

  ![image](screenshots/10%20get%20pods.PNG)

### View Control Center

- Set up port forwarding to Control Center web UI from local machine:

  ```cmd
  kubectl port-forward controlcenter-0 9021:9021
  ```

- Browse to Control Center: [http://localhost:9021](http://localhost:9021)

  ![image](screenshots/11%20overview.PNG)

## Create a kafka topic

- The topic should have at least 3 partitions because the azure blob storage has 3 partitions. Name the new topic: "expedia".

  ![image](screenshots/12%20create%20topic.PNG)

## Prepare the azure connector configuration

Change the `azure-source-cc-expedia.json` file, update by your Azure Storage credentials:
- `azblob.account.name`
- `azblob.account.key`
- `azblob.container.name`

## Upload the connector file through the API
Since Kafka Connect is intended to be run as a service, it also supports a REST API for managing connectors. By default this service runs on port 8083.
- Set up port forwarding to Connect pod from your local machine:
  ```cmd
  kubectl port-forward connect-0 8083:8083
  ```

- Upload the connector using following API:
  ```cmd
  curl -X POST -H "Content-Type: application/json" -d @/connectors/azure-source-cc-expedia.json http://localhost:8083/connectors
  ```

## Check results

- Connector is created:

  ![image](screenshots/13%20connector%20created.PNG)

- Topic data:

  ![image](screenshots/14%20topic%20data.PNG)

- Message transformation (date masking):

  ![image](screenshots/15%20transformation.png)

- Don't forget to destroy infrastructure afterwards with:
  ```
  terraform destroy
  ```