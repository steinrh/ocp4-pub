oc apply -f ~/kubelet-bootstrap-cred-manager-ds.yaml
oc project openshift-kube-controller-manager-operator
oc delete secrets/csr-signer-signer secrets/csr-signer -n openshift-kube-controller-manager-operator
