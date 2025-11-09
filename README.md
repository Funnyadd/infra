# Infra

Infrastructure managed with **Kubernetes** and **FluxCD**, used to easily configure and deploy apps on my home server (**FunnyServer**).  
Each environment (`staging`, `prod`) lives under `clusters/home/environments/` and automatically syncs from this repo.

---

## Repository layout (overview)

```
infra/
├── apps/                    # Applications
│   ├── metrics/             ## Metrics API for LOG680
│   └── mobilitysoft/        ## Mobilitysoft app for LOG680
│
└── clusters/
    └── home/
        ├── flux-system/     # Flux bootstrap + controllers
        ├── namespaces/      # Namespace definitions (prod/staging)
        ├── environments/    # Each environment composition
        │   ├── staging/
        │   │   └── kustomization.yaml
        │   └── prod/
        │       └── kustomization.yaml
        ├── image/           # Image Automation
        │   ├── automation-staging.yaml
        │   ├── automation-prod.yaml
        ├── namespaces-kustomization.yaml
        ├── staging-kustomization.yaml
        ├── prod-kustomization.yaml
        └── kustomization.yaml
```

---

## Syncing changes with Flux

### When manifests were changed in Git
```bash
# Reconcile the environments (forces Flux to reapply manifests)
flux reconcile kustomization prod -n flux-system --with-source
flux reconcile kustomization staging -n flux-system --with-source

# Check reconciliation and resource health
flux get kustomizations -A
flux tree kustomization prod -n flux-system
flux tree kustomization staging -n flux-system
```

---

## Restarting applications / picking up new secrets

If you changed secrets, ServiceAccounts, or imagePullSecrets:

```bash
kubectl -n prod rollout restart deploy/metrics
kubectl -n prod rollout restart deploy/mobilitysoft
kubectl -n staging rollout restart deploy/metrics
kubectl -n staging rollout restart deploy/mobilitysoft

# Check rollout status
kubectl -n prod rollout status deploy/metrics
kubectl -n prod rollout status deploy/mobilitysoft
```

---

## If an image was fixed but manifests didn’t change

Sometimes the only issue is a bad image tag.  
Force Kubernetes to pull the new one:

```bash
kubectl -n prod delete pod -l app.kubernetes.io/name=metrics
kubectl -n prod delete pod -l app.kubernetes.io/name=mobilitysoft
kubectl -n prod get pods -w
```

---

## Working with Flux Image Automation

Flux automatically tracks tags through `ImageRepository` + `ImagePolicy`  
and updates `apps/*/overlays/<env>/patch-deployment.yaml`.

### Force image automation refresh

```bash
# Update image repositories
flux reconcile imagerepository metrics -n flux-system
flux reconcile imagerepository mobilitysoft -n flux-system

# Refresh image policies
flux reconcile imagepolicy metrics-prod -n flux-system
flux reconcile imagepolicy mobilitysoft-prod -n flux-system
flux reconcile imagepolicy metrics-staging -n flux-system
flux reconcile imagepolicy mobilitysoft-staging -n flux-system

# Trigger automation to commit new tags
flux reconcile imageupdateautomation automation-prod -n flux-system
flux reconcile imageupdateautomation automation-staging -n flux-system

# Apply the new commit to the cluster
flux reconcile kustomization prod -n flux-system --with-source
flux reconcile kustomization staging -n flux-system --with-source
```

---

## Quick sanity checks

### View deployed images
```bash
kubectl -n prod get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{range .spec.template.spec.containers[*]}{.image}{"\n"}{end}{end}'
kubectl -n staging get deploy -o jsonpath='{range .items[*]}{.metadata.name}{" => "}{range .spec.template.spec.containers[*]}{.image}{"\n"}{end}{end}'
```

### Debug pull errors or CrashLoopBackOff
```bash
kubectl -n prod describe pod $(kubectl -n prod get pod -o name | head -n1) | sed -n '/Events:/,$p'
```

---

## Tips

- **targetNamespace** in env Kustomizations ensures apps land in the correct env (`prod` or `staging`).
- All Flux automation and repository objects live in `flux-system` namespace.
- `ImagePolicy` objects are per-environment (different tag filters per env).
- Adding a new app only requires:
  1. Creating `apps/<app>/{base,overlays/...}`
  2. Adding its overlays to `clusters/home/environments/<env>/kustomization.yaml`
  3. Adding its ImageRepository + ImagePolicies

---

### Example: check Flux health
```bash
flux get all -A
flux get kustomization -A
flux get image repository -A
flux get image policy -A
flux get image update -A
```
