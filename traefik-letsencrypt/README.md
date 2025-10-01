# Traefik avec Let's Encrypt DNS-01 Challenge

Ce répertoire contient une configuration complète de Traefik avec support Let's Encrypt utilisant le challenge DNS-01 pour obtenir des certificats wildcard.

## 📁 Structure

```
traefik-letsencrypt/
├── docker-compose.yml           # Configuration Docker Compose
├── .env.example                 # Template des variables d'environnement
├── request-wildcard-cert.sh     # Script certbot pour certificats wildcard
├── config/
│   ├── traefik.yml             # Configuration statique de Traefik
│   └── dynamic.yml             # Configuration dynamique (middlewares, TLS)
├── certs/                      # Certificats Let's Encrypt (générés automatiquement)
└── logs/                       # Logs Traefik
```

## 🚀 Démarrage rapide

### 1. Configuration des variables d'environnement

```bash
cd traefik-letsencrypt
cp .env.example .env
```

Éditez le fichier `.env` avec vos informations :

```bash
# Configuration du domaine
DOMAIN_NAME=example.com
LETSENCRYPT_EMAIL=admin@example.com

# Authentification du dashboard Traefik
# Générez avec: echo $(htpasswd -nb admin votre-mot-de-passe) | sed -e s/\\$/\\$\\$/g
TRAEFIK_DASHBOARD_AUTH=admin:$$apr1$$...

# DNS Provider (exemple Cloudflare)
CF_DNS_API_TOKEN=votre-token-cloudflare
```

### 2. Mise à jour de la configuration Traefik

Éditez `config/traefik.yml` pour configurer votre domaine et provider DNS :

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: votre-email@example.com  # ← Votre email
      dnsChallenge:
        provider: cloudflare          # ← Votre provider DNS
```

### 3. Lancement de Traefik

```bash
# Créer les répertoires nécessaires
mkdir -p certs logs

# Créer le fichier acme.json avec les bonnes permissions
touch certs/acme.json
chmod 600 certs/acme.json

# Démarrer Traefik
docker-compose up -d

# Vérifier les logs
docker-compose logs -f traefik
```

### 4. Accès au dashboard

Une fois Traefik démarré, accédez au dashboard :
- URL : `https://traefik.example.com` (remplacez par votre domaine)
- Utilisateur : `admin`
- Mot de passe : celui configuré dans `TRAEFIK_DASHBOARD_AUTH`

## 🔒 Obtenir des certificats wildcard avec certbot

Le script `request-wildcard-cert.sh` permet d'obtenir des certificats wildcard via certbot.

### Utilisation basique

```bash
# Production
./request-wildcard-cert.sh -d example.com -e admin@example.com -p cloudflare

# Test (staging)
./request-wildcard-cert.sh -d example.com -e admin@example.com -p cloudflare -s
```

### Options disponibles

```
-d DOMAIN        Nom de domaine (ex: example.com)
-e EMAIL         Email pour notifications Let's Encrypt
-p DNS_PROVIDER  Provider DNS (cloudflare, ovh, route53, google, digitalocean, azure)
-s               Utiliser le serveur staging (pour tests)
-h               Afficher l'aide
```

### Providers DNS supportés

#### Cloudflare
```bash
export CF_DNS_API_TOKEN="votre-token"
./request-wildcard-cert.sh -d example.com -e admin@example.com -p cloudflare
```

#### OVH
```bash
export OVH_ENDPOINT="ovh-eu"
export OVH_APPLICATION_KEY="votre-key"
export OVH_APPLICATION_SECRET="votre-secret"
export OVH_CONSUMER_KEY="votre-consumer-key"
./request-wildcard-cert.sh -d example.com -e admin@example.com -p ovh
```

#### AWS Route53
```bash
export AWS_ACCESS_KEY_ID="votre-access-key"
export AWS_SECRET_ACCESS_KEY="votre-secret-key"
export AWS_REGION="us-east-1"
./request-wildcard-cert.sh -d example.com -e admin@example.com -p route53
```

#### Google Cloud DNS
```bash
export GCE_PROJECT="votre-projet-gcp"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/credentials.json"
./request-wildcard-cert.sh -d example.com -e admin@example.com -p google
```

#### DigitalOcean
```bash
export DO_AUTH_TOKEN="votre-token"
./request-wildcard-cert.sh -d example.com -e admin@example.com -p digitalocean
```

#### Azure DNS
```bash
export AZURE_CLIENT_ID="votre-client-id"
export AZURE_CLIENT_SECRET="votre-client-secret"
export AZURE_SUBSCRIPTION_ID="votre-subscription-id"
export AZURE_TENANT_ID="votre-tenant-id"
./request-wildcard-cert.sh -d example.com -e admin@example.com -p azure
```

### Emplacement des certificats

Après génération, les certificats sont disponibles dans :
```
certs/certbot/live/example.com/
├── fullchain.pem   # Certificat complet (à utiliser dans la config)
├── privkey.pem     # Clé privée
├── chain.pem       # Chaîne de certificats
└── cert.pem        # Certificat seul
```

## 🔧 Configuration avancée

### Ajouter un nouveau service

Ajoutez un service dans `docker-compose.yml` avec les labels Traefik :

```yaml
services:
  mon-app:
    image: mon-image:latest
    networks:
      - traefik_network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.mon-app.rule=Host(`app.${DOMAIN_NAME}`)"
      - "traefik.http.routers.mon-app.entrypoints=websecure"
      - "traefik.http.routers.mon-app.tls=true"
      - "traefik.http.routers.mon-app.tls.certresolver=letsencrypt"
      - "traefik.http.services.mon-app.loadbalancer.server.port=8080"
```

### Middlewares disponibles

Les middlewares définis dans `config/dynamic.yml` :

- **security-headers** : Headers de sécurité HTTP
- **rate-limit** : Limitation de taux (100 req/s, burst 50)

Utilisation :
```yaml
labels:
  - "traefik.http.routers.mon-app.middlewares=security-headers,rate-limit"
```

### Changer de provider DNS

1. Modifiez `config/traefik.yml` :
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      dnsChallenge:
        provider: votre-provider  # ovh, route53, google, etc.
```

2. Ajoutez les variables d'environnement dans `.env` et `docker-compose.yml`

3. Redémarrez Traefik :
```bash
docker-compose down
docker-compose up -d
```

## 🔍 Surveillance et logs

### Logs en temps réel
```bash
docker-compose logs -f traefik
```

### Logs fichiers
```bash
# Logs Traefik
tail -f logs/traefik.log

# Logs d'accès
tail -f logs/access.log
```

### Vérification de la configuration
```bash
# Vérifier la syntaxe de la config
docker-compose config

# Lister les certificats
docker exec traefik cat /certs/acme.json | jq
```

## 🛠️ Dépannage

### Problème : Certificat non généré

1. Vérifiez les logs :
```bash
docker-compose logs traefik | grep -i error
```

2. Vérifiez la configuration DNS :
```bash
# Le domaine doit pointer vers votre serveur
dig +short example.com
dig +short *.example.com
```

3. Testez avec le serveur staging :
```yaml
# Dans config/traefik.yml
caServer: https://acme-staging-v02.api.letsencrypt.org/directory
```

### Problème : Dashboard inaccessible

1. Vérifiez que le conteneur est démarré :
```bash
docker-compose ps
```

2. Vérifiez les règles de routage :
```bash
docker exec traefik traefik version
```

3. Vérifiez l'authentification :
```bash
# Générez un nouveau hash
echo $(htpasswd -nb admin votre-password) | sed -e s/\\$/\\$\\$/g
```

### Problème : Erreur DNS challenge

1. Vérifiez les credentials du provider DNS dans `.env`
2. Assurez-vous que l'API du provider est activée
3. Vérifiez les permissions de l'API token (doit pouvoir modifier les DNS)

### Réinitialisation complète

```bash
# Arrêter et supprimer les conteneurs
docker-compose down

# Supprimer les certificats (attention : perte des certificats !)
rm -rf certs/acme.json

# Recréer avec les bonnes permissions
touch certs/acme.json
chmod 600 certs/acme.json

# Redémarrer
docker-compose up -d
```

## 📚 Ressources

- [Documentation Traefik](https://doc.traefik.io/traefik/)
- [Let's Encrypt DNS Providers](https://doc.traefik.io/traefik/https/acme/#providers)
- [Certbot Documentation](https://eff-certbot.readthedocs.io/)
- [DNS-01 Challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)

## 🔐 Sécurité

- **Ne jamais commiter** le fichier `.env` avec vos credentials
- Stockez `certs/acme.json` en lieu sûr (contient les clés privées)
- Utilisez des tokens API avec le minimum de permissions nécessaires
- Activez l'authentification 2FA sur vos comptes DNS provider
- Renouvelez régulièrement vos tokens API

## 📋 Checklist de production

- [ ] Variables d'environnement configurées dans `.env`
- [ ] Domaine DNS correctement configuré
- [ ] Permissions `chmod 600` sur `certs/acme.json`
- [ ] Dashboard Traefik protégé par mot de passe fort
- [ ] Serveur staging testé avant production
- [ ] Monitoring des logs activé
- [ ] Sauvegarde de `certs/acme.json` configurée
- [ ] Rotation des secrets API planifiée

## 📝 License

Ce projet est fourni à des fins éducatives dans le cadre du workshop ClusterAPI/k0smotron.
