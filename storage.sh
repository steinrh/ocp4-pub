oc create namespace openshift-nfs-storage
oc label namespace openshift-nfs-storage "openshift.io/cluster-monitoring=true"
oc project openshift-nfs-storage
cd kubernetes-incubator/nfs-client/
NAMESPACE=`oc project -q`
export KUBECONFIG=~/ocp4/auth/kubeconfig 
cd kubernetes-incubator/nfs-client/
sed -i'' "s/namespace:.*/namespace: $NAMESPACE/g" ./deploy/rbac.yaml 
sed -i'' "s/namespace:.*/namespace: $NAMESPACE/g" ./deploy/deployment.yaml 
 oc create -f deploy/rbac.yaml
oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:$NAMESPACE:nfs-client-provisioner
vim deploy/deployment.yaml 
cat > deploy/class.yaml << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
provisioner: storage.io/nfs # or choose another name, must match deployment's env PROVISIONER_NAME'
parameters:
  archiveOnDelete: "false"
EOF
oc create -f deploy/class.yaml 
oc create -f deploy/deployment.yaml 
oc get pods -n openshift-nfs-storage
oc logs -f nfs-client-provisioner-755c9bcf77-b55nn
oc patch storageclass managed-nfs-storage -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"
}}}'
cat > deploy/pvc-registry.yaml << EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: image-registry-nfs
  annotations:
    volume.beta.kubernetes.io/storage-class: "managed-nfs-storage"
  namespace: openshift-image-registry
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
EOF

oc create -f deploy/pvc-registry.yaml
oc edit configs.imageregistry.operator.openshift.io
