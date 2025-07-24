## Setup the environment

The current demo is done on MicroK8s, but this can also be done on other substrates, like AKS. 

### Setup MicroK8s

Install MicroK8s

```shell
sudo snap install microk8s --channel 1.32-strict/stable
```

Configure the deployment

```shell
sudo microk8s enable hostpath-storage dns rbac storage                                                    
sudo snap alias microk8s.kubectl kubectl              
microk8s config > ~/.kube/config
```

Wait for K8s to be ready, by also checking with `kubectl get pod -A` to see the various services going up.

### Enable MetalLB

Enable the MetalLB, by first fetching the available IP:

```shell
ip -4 -j route get 2.2.2.2 | jq -r '.[] | .prefsrc' 
```

and then configuring the metallb addon (please provide a range of at least a couple of IPs):

```shell
sudo microk8s enable metallb:172.21.0.247-172.21.0.250
```

### Enable MinIO

To enable MinIO, just use the addon

```shell
sudo microk8s enable minio
```

Once that microk8s is up and running, to can easily retrieve the `access-key`, `secret-key` and `endpoint` using the bash script bundled in this repo:

```shell
source ./bin/s3.sh create
```

This should provide an output of the format:

```shell
access_key:<access_key>,secret_key:<secret_key>,host:<host>
```

### Create a bucket in the S3 storage

Install the `aws-cli` snap

```shell
sudo snap install aws-cli --channel `v2/stable`
```

and configure the aws client, by first specifying the endpoint

```shell
aws configure set endpoint_url "http://<host>:80"
```

and then the credentials informations:

```shell
aws configure
```

That should start a prompt interaction:

```shell
AWS Access Key ID [****************4wxq]: <secret_key>
AWS Secret Access Key [****************cAkV]: <access_key>
Default region name [eu-central-1]: 
Default output format [None]: 
```

At this point, test that the s3 client is configured correctly by testing with:

```shell
aws s3 ls
```

This should not provide any output, as there are no buckets there yet. We can create a bucket using:

```shell
aws s3 mb s3://spark-test
```

And then check that the bucket has been created using:

```shell
$ aws s3 ls                
2025-07-21 17:48:22 spark-test
```

## Deploy the data warehouse stack

### Setup Juju

Start by installing the Juju snap

```shell
sudo snap install juju --channel 3.6/stable
```

Then bootstrap a new controller on MicroK8s, using:

```shell
juju bootstrap microk8s micro
```

### Deploy the datalake stack

The deployment will be carried out using `terraform`. Therefore, first install the `terraform` snap using:

```shell
sudo snap install terraform --channel `latest/stable`
```

That - at the time of the demo testing - ships version `1.12.2`.

The terraform plan needs to be configure with:
1. the endpoints and credentials of the juju controller
2. the endpoint of the MinIO backend

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

#### Configuring MinIO

The information of MinIO endpoint can be instead configure using the `test.aut.tfvars.json` file. Therefore, go to the `terraform` folder, and then create a `test.auto.tfvars.json` file to feed the variable to point to the MinIO instance and the right bucket:

```shell
# content of test.auto.tfvars.json
{
  "storage_backend": "s3",
  "s3": {
    "region": "eu-central-1",
    "bucket": "spark-test",
    "endpoint": "http://<host>:80"
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

Once the terraform deployment process is finished, remember to configure the credentials for `s3` using:

```shell
juju run --model spark s3/0 \
  sync-s3-credentials \
  access-key=<access_ket> \
  secret-key=<secret_key> \
```

Wait for everything to go into `active/idle` state.

### Inspecting the deployment

We just provide the output of the juju status for reference:

```shell
Model  Controller  Cloud/Region        Version  SLA          Timestamp
kafka  micro       microk8s/localhost  3.6.8    unsupported  18:47:08+02:00

SAAS                             Status  Store  URL
grafana-dashboards               active  local  admin/cos.grafana-dashboards
integration-hub                  active  local  admin/spark.integration-hub
loki-logging                     active  local  admin/cos.loki-logging
metastore                        active  local  admin/spark.metastore
prometheus-receive-remote-write  active  local  admin/cos.prometheus-receive-remote-write

App              Version  Status  Scale  Charm              Channel                   Rev  Address         Exposed  Message
admin                     active      1  data-integrator    latest/stable             181  10.152.183.157  no       
agent            0.40.4   active      1  grafana-agent-k8s  1/stable                  121  10.152.183.240  no       tracing: off
kafka            3.9.0    active      1  kafka-k8s          3/stable                   82  10.152.183.148  no       
producer                  active      1  kafka-test-app     latest/stable              11  10.152.183.99   no       Topic test-topic enabled with process producer
spark-streaming           active      1  spark-test-app     latest/edge/dpe7677-demo    4  10.152.183.254  no       
zookeeper        3.9.2    active      1  zookeeper-k8s      3/stable                   78  10.152.183.24   no       

Unit                Workload  Agent  Address      Ports  Message
admin/0*            active    idle   10.1.99.143         
agent/0*            active    idle   10.1.99.176         tracing: off
kafka/0*            active    idle   10.1.99.151         
producer/0*         active    idle   10.1.99.156         Topic test-topic enabled with process producer
spark-streaming/0*  active    idle   10.1.99.154         
zookeeper/0*        active    idle   10.1.99.150     
```

```shell
❯ juju status --model spark
Model  Controller  Cloud/Region        Version  SLA          Timestamp
spark  micro       microk8s/localhost  3.6.8    unsupported  18:47:29+02:00

App              Version  Status  Scale  Charm                      Channel        Rev  Address         Exposed  Message
certificates              active      1  self-signed-certificates   latest/stable  163  10.152.183.68   no       
data-integrator           active      1  data-integrator            latest/stable  161  10.152.183.88   no       
history-server            active      1  spark-history-server-k8s   3.4/edge        40  10.152.183.142  no       
integration-hub           active      1  spark-integration-hub-k8s  latest/edge     64  10.152.183.71   no       
kyuubi                    active      1  kyuubi-k8s                 latest/edge    100  10.152.183.30   no       
kyuubi-users     14.11    active      1  postgresql-k8s             14/stable      281  10.152.183.167  no       
metastore        14.11    active      1  postgresql-k8s             14/stable      281  10.152.183.109  no       
s3                        active      1  s3-integrator              1/stable       145  10.152.183.234  no       
zookeeper        3.9.2    active      1  zookeeper-k8s              3/stable        78  10.152.183.112  no       

Unit                Workload  Agent  Address      Ports  Message
certificates/0*     active    idle   10.1.99.145         
data-integrator/0*  active    idle   10.1.99.172         
history-server/0*   active    idle   10.1.99.173         
integration-hub/0*  active    idle   10.1.99.158         
kyuubi-users/0*     active    idle   10.1.99.171         Primary
kyuubi/0*           active    idle   10.1.99.155         
metastore/0*        active    idle   10.1.99.165         Primary
s3/0*               active    idle   10.1.99.174         
zookeeper/0*        active    idle   10.1.99.170         

Offer            Application      Charm                      Rev  Connected  Endpoint               Interface              Role
certificates     certificates     self-signed-certificates   163  0/0        certificates           tls-certificates       provider
integration-hub  integration-hub  spark-integration-hub-k8s  64   1/1        spark-service-account  spark_service_account  provider
metastore        metastore        postgresql-k8s             281  1/1        database               postgresql_client      provider
send-ca-cert     certificates     self-signed-certificates   163  0/0        send-ca-cert           certificate_transfer   provider
```

```shell
❯ juju status --model cos  
Model  Controller  Cloud/Region        Version  SLA          Timestamp
cos    micro       microk8s/localhost  3.6.8    unsupported  18:47:53+02:00

App           Version  Status  Scale  Charm             Channel        Rev  Address         Exposed  Message
alertmanager  0.27.0   active      1  alertmanager-k8s  1/stable       162  10.152.183.223  no       
catalogue              active      1  catalogue-k8s     1/stable        87  10.152.183.48   no       
grafana       9.5.3    active      1  grafana-k8s       1/stable       151  10.152.183.84   no       
loki          2.9.6    active      1  loki-k8s          1/stable       199  10.152.183.93   no       
prometheus    2.52.0   active      1  prometheus-k8s    1/stable       247  10.152.183.163  no       
traefik       2.11.0   active      1  traefik-k8s       latest/stable  236  10.152.183.62   no       Serving at 172.21.0.247

Unit             Workload  Agent  Address      Ports  Message
alertmanager/0*  active    idle   10.1.99.163         
catalogue/0*     active    idle   10.1.99.144         
grafana/0*       active    idle   10.1.99.179         
loki/0*          active    idle   10.1.99.178         
prometheus/0*    active    idle   10.1.99.177         
traefik/0*       active    idle   10.1.99.159         Serving at 172.21.0.247

Offer                            Application   Charm             Rev  Connected  Endpoint              Interface                Role
alertmanager-karma-dashboard     alertmanager  alertmanager-k8s  162  0/0        karma-dashboard       karma_dashboard          provider
grafana-dashboards               grafana       grafana-k8s       151  1/1        grafana-dashboard     grafana_dashboard        requirer
loki-logging                     loki          loki-k8s          199  1/1        logging               loki_push_api            provider
prometheus-receive-remote-write  prometheus    prometheus-k8s    247  1/1        receive-remote-write  prometheus_remote_write  provider
```

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

After a few minutes, you can also check that data is written into the object storage by inspecting the bucket:

```shell
aws s3 ls spark-test/warehouse/<table_name>/
```

where the table name is the id of the `metastore` <> `spark-streaming` relation.
