## Explore the data using DBBeaver

DBeaver is an free to use DB manager client, able to connect to several type of database.

### Retrieve credentials

A `data-integrator` is already deployed alongside `kyuubi` to provide credentials to login with on the JDBC endpoint. To retrieve these credentials use the following action:

```shell
juju run --model spark data-integrator/0 get-credentials
```

This should provide `username`, `password`, `tls-ca` and `endpoint` to be used to connect.

### Setup the encryption

Make sure that you have a java runtime installed in your system:

```
java -version
```

If Java is not currently installed, you'll get the following output:

```
Command 'java' not found, but can be installed with:

sudo apt install default-jre              # version 2:1.11-72build1, or
sudo apt install openjdk-11-jre-headless  # version 11.0.14+9-0ubuntu2
sudo apt install openjdk-17-jre-headless  # version 17.0.2+8-1
sudo apt install openjdk-18-jre-headless  # version 18~36ea-1
sudo apt install openjdk-8-jre-headless   # version 8u312-b07-0ubuntu1
```

You can pick one of the options above.

You can then create the trust store, by first copying the CA cert information into a `cert.pem` file, e.g.

```
# cert.pem
-----BEGIN CERTIFICATE-----
<signature here>
-----END CERTIFICATE-----%                
```

and then load this into a trust store to be created:

```
keytool -import -v -alias alias -file <cert.pem>  -storepass <random-password> -noprompt -keystore <keystore-filename>
```

### DBeaver setting

To connect to a Kyuubi endpoint using DBeaver, follow the following steps in the DBeaver GUI:

1. First open the software and register a new DB connection by clicking on `File > New`, and then select `Database Connection` in the dropbox.
2. Select "Apache Kyuubi" in the list of supported databases (you can also find it under `Hadoop / BigData` subsection). Click next.
3. If encryption is enabled, click on "Driver Settings" and then customize the `URL template` by adding SSL/trustore specifications in the next dialog. We recommend to use the following value:
```
jdbc:hive2://{host}[:{port}][/{database}];ssl=true;trustStorePassword=<password>;sslTrustStore=</path/to/trustore>
```
Click `Ok` to register the new settings, and verify that the `JDBC URL` (which should not be editable) reflects the new changes. 
4. Add the various authentication informations, such as `Host`, `Database/Schema` (use `default` as the spark-streaming process will be writing under the `default` schema), `Username` and `Password`. Click finish, and verify that the connection works appropriately. 

You can now start using DBeaver to explore your dataset on Apache Kyuubi. 