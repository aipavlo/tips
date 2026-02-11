#kubectl
kubectl config use-context k8s_context
# list namespaces
kubectl get ns

# confluent connector
kubectl confluent connector list -n k8s_namespace

kubectl confluent connector restart --name=connector_name

kubectl confluent connector --name connector_name -n k8s_namespace

kubectl confluent connector pause --name connector_name -n k8s_namespace

# stream logs
kubectl logs -n k8s_namespace k8s_pod --since=10m -f | grep -F "kafka_connector"

# delete subject from schema-registry
kubectl -n k8s_namespace get svc svc_schemaregistry -o jsonpath='{.spec.ports[0].port}' # check ports
kubectl -n k8s_namespace port-forward svc/svc_schemaregistry 18081:$(kubectl -n k8s_namespace get svc svc_schemaregistry -o jsonpath='{.spec.ports[0].port}')
# soft delete
curl -s -X DELETE "http://localhost:18081/subjects/target.subject-key"
curl -s -X DELETE "http://localhost:18081/subjects/target.subject-value"
# hard delete
curl -s -X DELETE "http://localhost:18081/subjects/target.subject-key?permanent=true"
curl -s -X DELETE "http://localhost:18081/subjects/target.subject-value?permanent=true"