oc delete all --all
oc delete secret zync
oc delete pvc system-storage mysql-storage system-redis-storage backend-redis-storage
oc delete configmap redis-config smtp system
