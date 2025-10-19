# Infra

Infrastructure using kubernetes with **FluxCD** to configure apps easily and deploy them on my home server (**FunnyServer**).

## How to sync changes

### If you changed manifests in Git

1. Commit & push.
2. Tell Flux to pull/apply now:

```shell
# Prod & Staging (adjust names/namespaces if different)
flux reconcile kustomization prod -n flux-system --with-source
flux reconcile kustomization staging -n flux-system --with-source

# watch health
flux get kustomizations -A
flux tree kustomization prod -n flux-system
```

### If you added/changed imagePullSecrets or ServiceAccount

Existing pods won’t see that change—roll them:

```shell
kubectl -n prod rollout restart deploy/log680
kubectl -n staging rollout restart deploy/log680

kubectl -n prod rollout status deploy/log680
kubectl -n staging rollout status deploy/log680
```

### If the fix was “the image/tag is now good” (no manifest change)

Just nuke the failing pods so they re-pull:

```shell
kubectl -n prod delete pod -l app=log680
kubectl -n staging delete pod -l app=log680
kubectl -n prod get pods -w
```

### If you use Flux Image Automation (ImagePolicy/ImageRepository)

Force the automation to refresh tags and commit, then apply:

```shell
flux reconcile imagerepository metrics -n flux-system
flux reconcile imagerepository mobilitysoft -n flux-system
flux reconcile imagepolicy metrics-prod -n flux-system
flux reconcile imagepolicy mobilitysoft-prod -n flux-system

# pull the new commit into the cluster
flux reconcile kustomization prod -n flux-system --with-source
```

### Quick sanity checks
```shell
# Confirm the live images on the Deployment
kubectl -n prod get deploy log680 -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{" => "}{.image}{"\n"}{end}'

# If it still fails, show the exact pull error
kubectl -n prod describe pod $(kubectl -n prod get pod -l app=log680 -o name | head -n1) | sed -n '/Events:/,$p'
```
