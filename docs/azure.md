## Setup the environment

The current demo is done on MicroK8s, but this can also be done on other substrates, like AKS. 

### Setup AKS

Install the `azure-cli` tool

```shell
sudo snap install azcli --channel latest/stable
```

which installs version 2.67.0+v10.

Login to Azure using the CLI to grant the CLI tool user permissions:

```shell
az login
```

You will re-directed to perform the authentication in the Azure portal.

At this point, if your user has permission, you can first create a resource group

```shell
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}
```

and then create an AKS cluster

```shell
 az aks create \                                                      
    --resource-group ${RESOURCE_GROUP} \
    --name ${NAME} \
    --kubernetes-version ${K8S_VERSION} \
    --node-count 3 \
    --node-vm-size Standard_D8s_v3 \
    --node-osdisk-size 100 \
    --node-osdisk-type Managed \
    --os-sku Ubuntu \
    --no-ssh-key
```

Get the kubeconfig file to access and manage the AKS K8s cluster:

```shell
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${NAME} --admin
```

At this point, just verify that you can correctly access the cluster by e.g. listing all pods:

```shell
kubectl get pod -A
```

## Deploy the data warehouse stack

### Setup Juju

Start by installing the Juju snap

```shell
sudo snap install juju --channel 3.6/stable
```

Add the K8s client connected to AKS:

```shell
juju add-k8s aks --client
```

Then bootstrap a new controller on AKS, using:

```shell
juju bootstrap aks
```

### Deploy the datalake stack

The deployment will be carried out using `terraform`. Therefore, first install the `terraform` snap using:

```shell
sudo snap install terraform --channel `latest/stable`
```

That - at the time of the demo testing - ships version `1.12.2`.

The terraform plan needs to be configure with:
1. the endpoints and credentials of the juju controller
2. information for creating the Azure Blob Storage container

#### Configuring Juju

The pointers to the Juju controller can be fed via the `TF_VAR_*` environment variables. You can use the bash script in `./bin/get-vars.sh` to automatically read these configuration and set the corresponding environment variables

```shell
source ./bin/get-vars.sh
```

Just verify that the variables are indeed set by using:

```shell
$ env | grep TF_VAR
TF_VAR_JUJU_CONTROLLER_IPS=...
TF_VAR_JUJU_USERNAME=...
TF_VAR_JUJU_PASSWORD=...
TF_VAR_JUJU_CA_CERTIFICATE=...
TF_VAR_K8S_CLOUD=microk8s
TF_VAR_K8S_CREDENTIAL=microk8s
```

#### Configuring Azure Blob storage

The information of MinIO endpoint can be instead configure using the `test.aut.tfvars.json` file. Therefore, go to the `terraform` folder, and then create a `test.auto.tfvars.json` file to feed the variable to point to the MinIO instance and the right bucket:

```shell
# content of test.auto.tfvars.json
{
    "storage_backend": "azure_storage",
    "azure_storage": {
	   "storage_account": "testdemokyuubi",
	   "resource_group": "spark-test-app-storage"
    }
}
```

### Deploying the datalake stack
 
At this point, we can deploy the terraform module. To do so, first go in the `terraform` folder and initialize the modules:

```shell
terraform init
```

Make sure that everything is setup correctly using 

```shell
terraform plan
```

You can review the various resources to be created by terraform. Deploy everything with terraform using:

```shell
terraform apply -auto-approve
```

Wait for everything to go into `active/idle` state.

## Verify the deployment

The deployment comes with three Juju models: `kafka`, `spark`, and `cos`. In the `kafka` model there are the ingestion and processing charms, `producer` and `spark-streaming` respectively.
While the deployment will already start the producer to ingest data into Kafka, the aggregation job needs to be started manually to prevent racing condition to fail the job.

So after everything is in `active/idle` state, checks that the Kafka producer process is correctly working by ssh-ing into the unit, and tailing the output files that can be found under the `/tmp` folder (look for the two files containing the std out and std err).

```shell
juju ssh --model kafka producer/0 "tail -f /tmp/*_producer.log"
```

Once that you have verified that the Kafka process is correctly pushing data, you can then start the `spark-streaming` process to produce aggregation that are consolidated into a HiveTable stored on MinIO backend:

```shell
juju run --model kafka spark-streaming/0 start-process
```

You can verify that the process has started by both checking the logs in the charm:

```shell
juju ssh --model kafka --container spark  spark-streaming/0 "pebble logs -f"
```

After a few minutes, you can also check that data is written into the object storage by inspecting the azure container and make sure that data are stored under:

```shell
<container>/warehouse/<table_name>/
```

where the table name is the id of the `metastore` <> `spark-streaming` relation.
