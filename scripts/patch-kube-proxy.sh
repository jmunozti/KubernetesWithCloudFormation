#!/bin/bash

export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl -n kube-system patch --type json daemonset kube-proxy -p "$(cat <<'EOF'
[
    {
        "op": "add",
        "path": "/spec/template/spec/volumes/0",
        "value": {
            "emptyDir": {},
            "name": "kube-proxy-config"
        }
    },
    {
        "op": "replace",
        "path": "/spec/template/spec/containers/0/volumeMounts/0",
        "value": {
          "mountPath": "/var/lib/kube-proxy",
          "name": "kube-proxy-config"
        }
    },
    {
        "op": "add",
        "path": "/spec/template/spec/initContainers",
        "value": [
            {
                "command": [
                    "sh",
                    "-c",
                    "sed -e \"s/hostnameOverride: \\\"\\\"/hostnameOverride: \\\"${NODE_NAME}\\\"/\" /var/lib/kube-proxy-configmap/config.conf > /var/lib/kube-proxy/config.conf && cp /var/lib/kube-proxy-configmap/kubeconfig.conf /var/lib/kube-proxy/"
                ],
                "env":[
                    {
                        "name": "NODE_NAME",
                        "valueFrom": {
                            "fieldRef": {
                                "apiVersion": "v1",
                                "fieldPath": "spec.nodeName"
                            }
                        }
                    }
                ],
                "image": "busybox",
                "name": "config-processor",
                "volumeMounts": [
                    {
                        "mountPath": "/var/lib/kube-proxy-configmap",
                        "name": "kube-proxy"
                    },
                    {
                        "mountPath": "/var/lib/kube-proxy",
                        "name": "kube-proxy-config"
                    }
                ]
            }
        ]
    }
]
EOF
)"
