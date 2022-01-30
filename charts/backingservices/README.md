# BackingServices Helm chart

The Pega Infinity backing service is a feature which you can deploy as an independent service module. For example `Search and Reporting Service` or `SRS` backing service can replace the embedded search feature of Pega Infinity Platform. To use it in your deployment, you provision and deploy it independently as an external service which provides search and reporting capabilities with a Pega Infinity environment.  

The backingservices chart supports deployment options for Search and Reporting Service (SRS). You configure this SRS into the `pega` namespace for your Pega Infinity deployment.

## Configuring a backing service with your pega environment

You can provision this SRS into your `pega` environment namespace, with the SRS endpoint configured with the Pega Infinity environment. When you include the SRS into your pega namespace, the service endpoint is included within your Pega Infinity environment network to ensure isolation of your application data.

## Search and Reporting Service support

The Search and Reporting Service provides next generation search and reporting capabilities for Pega Infinity 8.6 and later.

This service replaces the legacy search module from the platform with an independently deployable and scalable service along with the built-in capabilities to support more than one Pega environments with its data isolation features in Pega Infinity 8.6 and later.
The service deployment provisions runtime service pods along with a dependency on a backing technology ElasticSearch service for storage and retrieval of data. 

### SRS Version compatibility matrix

Pega Infinity version   | SRS version   | ElasticSearch version     | Description
---                     | ---           | ---                       | ---
< 8.6                   | NA            | NA                        | SRS can be used with Pega Infinity 8.6 and later
\>= 8.6                 | \>=1.12.0     | 7.9.3                    | Pega Infinity 8.6 and later supports using a Pega-provided platform-services/search-n-reporting-service Docker Image that is tagged with version 1.12.0 or later (Pega recommends using 1.16.1 or later). All SRS Docker image versions are certified to support Elasticsearch version 7.9.3.

### SRS runtime configuration

The values.yaml provides configuration options to define the deployment resources along with option to either provision ElasticSearch cluster automatically for data storage, or you can choose to configure an existing managed elasticsearch cluster to use as a datastore with the SRS runtime. 

If an externally managed elasticsearch cluster is being used, make sure the service is accessible to the k8s cluster where SRS is deployed.

You may enable the component of [Elasticsearch](https://github.com/helm/charts/tree/master/stable/elasticsearch/values.yaml) in the backingservices by configuring the 'srs.srsStorage' section in values.yaml file to deploy ElasticSearch cluster automatically. For more configuration options available for each of the components, see their Helm Charts.

Note: Pega does **not** actively update the elasticsearch dependency in `requirements.yaml`. To leverage SRS, you should:
* Update the elasticsearch `version` value, or
* Disable deploying elasticsearch by setting `srs.srsStorage.provisionInternalESCluster` to false.

### Configuration settings

Configuration                       | Usage
---                                 | ---
`enabled`                           | Enable the Search and Reporting Service deployment as a backing service.
`deploymentName`                    | Specify the name of your SRS cluster. Your deployment creates resources prefixed with this string. This is also the service name for the SRS.
`srsRuntime`                        | Use this section to define specific resource configuration options like image, replica count, cpu and memory resource settings in the SRS.
`elasticsearch`                     | Define the elasticsearch cluster configurations. The [Elasticsearch](https://github.com/helm/charts/tree/master/stable/elasticsearch/values.yaml) chart defines the values for elasticsearch provisioning in the cluster.
`srsStorage.provisionInternalESCluster` | <ul><li>Enable this parameter to provision an internally managed and secured Elasticsearch cluster to be used with the SRS (Requires you to run `$ make es-prerequisite NAMESPACE=<NAMESPACE_USED_FOR_DEPLOYMENT>`).</li><li>Disable this parameter to use your own Elasticsearch service with the SRS.</li></ul>

Example:

```yaml
srs:
  enabled: true
  deploymentName: "YOUR_SRS_DEPLOYMENT_NAME"
  srsRuntime:
    #srs-service values
    replicaCount: 2
    srsImage: "YOUR_SRS_IMAGE:TAG"
    imagepullPolicy: IfNotPresent
    resources:
      limits:
        cpu: 1300m
        memory: "2Gi"
      requests:
        cpu: 650m
        memory: "2Gi"
    serviceType: "ClusterIP"
    env:
      #AuthEnabled may be set to true when there is an authentication mechanism in place between SRS and Pega Infinity.
      AuthEnabled: false
      PublicKeyURL:

  srsStorage:
    # To configure authentication for the externally managed Elasticsearch cluster to use Basic Authentication then uncomment
    # add the parameters, srs.srsStorage.basicAuthentication.username and srs.srsStorage.basicAuthentication.password
    #    basicAuthentication:
    #      username: "BASIC_AUTH_USERNAME"
    #      password: "BASIC_AUTH_PASSWORD"
    # To configure authentication for the externally managed Elasticsearch cluster to use an AWS IAM Role then uncomment and
    # add the parameters, srs.srsStorage.awsIAM and srs.srsStorage.awsIAM.region
    # srs.srsStorage.awsIAM's srs.srsStorage.awsIAM.region value
    #    awsIAM:
    #      region: "AWS_ELASTICSEARCH_REGION"

    # set `requireInternetAccess` to true when the elasticsearch domain is outside of the Kubernetes cluster network  and is available over internet
#    requireInternetAccess: true
```
