    BASE_DOMAIN="$(oc get dns.config/cluster -o 'jsonpath={.spec.baseDomain}')"
    INGRESS_DOMAIN="$(oc get ingress.config/cluster -o 'jsonpath={.spec.domain}')"
    openssl genrsa -out example-ca.key 2048
    openssl req -x509 -new -key example-ca.key -out example-ca.crt -days 1 -subj "/C=US/ST=NC/L=Chocowinity/O=OS3/OU=Eng/CN=$BASE_DOMAIN"
    openssl genrsa -out example.key 2048
    openssl req -new -key example.key -out example.csr -subj "/C=US/ST=NC/L=Chocowinity/O=OS3/OU=Eng/CN=*.$INGRESS_DOMAIN"
    openssl x509 -req -in example.csr -CA example-ca.crt -CAkey example-ca.key -CAcreateserial -out example.crt -days 1
    oc -n openshift-config create configmap custom-ca --from-file=ca-bundle.crt=example-ca.crt
    oc patch proxy/cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"custom-ca"}}}'
    oc -n openshift-ingress create secret tls custom-default-cert --cert=example.crt --key=example.key
    oc -n openshift-ingress-operator patch ingresscontrollers/default --type=merge --patch='{"spec":{"defaultCertificate":{"name":"custom-default-cert"}}}'
