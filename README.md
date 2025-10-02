# Infra

Configuration de l'infrastructure Kubernetes pour l'organisation.

## Structure du dépôt

```shell
k8s-infra/
├─ docker-compose.yml       # Définition des services à déployer
├─ kompose.yaml             # Base pour tous les déploiements
├─ k8s/
│  ├─ base/                 # Configuration de base généré par le Makefile
│  └─ overlays/             # Défini les overlays pour configurer chaque environnement indépendemment
│     ├─ staging/
│     │  ├─ kustomization.yaml
│     │  ├─ patch-images.yaml
│     │  ├─ patch-ingress.yaml
│     │  └─ patch-secrets.yaml
│     ├─ prod/
│     │  ├─ kustomization.yaml
│     │  ├─ patch-images.yaml
│     │  ├─ patch-ingress.yaml
│     │  └─ patch-secrets.yaml
│     └─ pr-template/
│        ├─ kustomization.yaml
│        ├─ patch-images.yaml
│        ├─ patch-ingress.yaml
│        └─ patch-secrets.yaml
├─ deploy/
│  └─ secrets-template.env  # Les clés des secrets
├─ Makefile                 # (Local) Crée la configuration de base du déploiment avec Kompose et applique les changements avec Kustomize
└─ .github/
   └─ workflows/
      ├─ render.yml         # Regénère les configuration de kubernetes à partir du docker-compose.yml quand il y un nouveau changement
      ├─ deploy-envs.yml    # Déploie en pr/staging/prod
      └─ pr-preview.yml     # Crée/néttoie les déploiements de pr preview
```
