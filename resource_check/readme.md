Before playbook run deploy vpa resource

```
oc get dc -A --no-headers -o jsonpath='{ range.items[*]}{"\t"}'NS:'{.metadata.namespace}':NAME:'{.metadata.name}{"\n"}' | grep -vE "openshift|kube|default" > config
```
```yaml
while read -r i;do
cat << EOF | oc create -f -
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: $(echo $i | cut -f4 -d:) 
  namespace: $(echo $i | cut -f2 -d:)
spec:
  targetRef:
    apiVersion: "apps.openshift.io/v1"
    kind:       DeploymentConfig 
    name:       $(echo $i | cut -f4 -d:) 
  updatePolicy:
    updateMode: "Off"
EOF
done < config
```
```yaml
while read -r i;do
cat << EOF | oc create -f -
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: $(echo $i | cut -f4 -d:) 
  namespace: $(echo $i | cut -f2 -d:)
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment 
    name:       $(echo $i | cut -f4 -d:) 
  updatePolicy:
    updateMode: "Off"
EOF
done < config
```
```
oc get project -A --no-headers | awk '{print $1}' | grep -vE "openshift|kube|default" > config
```
```bash
echo "namespace,app_name,requests-limits,target_resource,upperBound_resource" > lab_cluster
while read -r i;do 
if [[ $(oc get deploymentconfigs -n $i --no-headers | wc -l) != 0 ]]; then
   oc get dc -n $i --no-headers | awk '{print $1}' > result
   while read -r app;do
      ARRAY=()
      result_of_dc=$(oc get dc $app -n $i -o jsonpath='{.metadata.namespace};{.metadata.name};{..resources.requests};{..resources.limits}')
      result_of_vpa=$(oc get vpa $app -n $i -o jsonpath='{.status.recommendation.containerRecommendations[*].target};{.status.recommendation.containerRecommendations[*].upperBound}')
      ARRAY+=($result_of_dc $result_of_vpa)
      echo "${ARRAY[@]}" >> lab_cluster
      sed -i '/^$/d' lab_cluster
   done < result 
elif [[ $(oc get deploy -n $i --no-headers | wc -l) != 0 ]]; then
     oc get deploy -n $i --no-headers | awk '{print $1}' > result
     while read -r app;do
       ARRAY=()
       result_of_deploy=$(oc get deploy $app -n $i -o jsonpath='{.metadata.namespace};{.metadata.name};{..resources.requests};{..resources.limits}')
       result_of_vpa=$(oc get vpa $app -n $i -o jsonpath='{.status.recommendation.containerRecommendations[*].target};{.status.recommendation.containerRecommendations[*].upperBound}')
       ARRAY+=($result_of_deploy $result_of_vpa)
       echo "${ARRAY[@]}" >> lab_cluster
       sed -i '/^$/d' lab_cluster
   done < result 
fi
done < config
```
