# Déploiement Backend — Leaks Survey

## Architecture

```
[GitHub] → (push main) → [GitHub Actions] → (SCP + SSH) → [Oracle VM]
                                                              └── Docker : backend Spring Boot (port 8080)
                                                              └── PM2    : n8n (autre projet)
```

- **Backend** : Spring Boot JAR dans un conteneur Docker
- **Base de données** : H2 en mode fichier (volume Docker persistant)
- **Frontend** : APK Flutter partagé manuellement (hors CI/CD)
- **VM** : Oracle Free Tier (Ubuntu) — n8n tourne déjà avec PM2

---

## Prérequis

- VM Oracle avec Ubuntu 22.04+
- Docker installé sur la VM
- Clé SSH pour accéder à la VM
- Compte GitHub avec accès au repo

---

## Fichiers de déploiement

### `backend/Dockerfile`

```dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### `docker-compose.yml` (racine du projet)

```yaml
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
    restart: always
```

### `.github/workflows/deploy.yml`

```yaml
name: Deploy Backend
on:
  push:
    branches: [main]
    paths: ['backend/**', 'Dockerfile', 'docker-compose.yml']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build with Maven
        run: cd backend && mvn clean package -DskipTests

      - name: Copy files to VM
        uses: appleboy/scp-action@v0.1.4
        with:
          host: ${{ secrets.HOST }}
          username: ubuntu
          key: ${{ secrets.SSH_KEY }}
          source: "backend/target/*.jar,Dockerfile,docker-compose.yml"
          target: "/opt/leaks-backend"

      - name: Restart Docker container
        uses: appleboy/ssh-action@v0.1.5
        with:
          host: ${{ secrets.HOST }}
          username: ubuntu
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /opt/leaks-backend
            docker compose down
            docker compose up -d --build
            docker image prune -f
```

---

## Setup unique sur la VM

```bash
# 1. Installer Docker (si pas déjà fait)
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu

# 2. Créer le dossier de déploiement
mkdir -p /opt/leaks-backend/data

# 3. Vérifier que le port 8080 est libre
sudo ss -tlnp | grep 8080
```

---

## Secrets GitHub à configurer

Dans **Settings → Secrets and variables → Actions** :

| Secret | Valeur |
|--------|--------|
| `HOST` | IP publique de la VM Oracle |
| `SSH_KEY` | Contenu de la clé privée (fichier .pem) |

---

## Utilisation quotidienne

### Déploiement

1. Travailler normalement sur le code
2. `git push origin main`
3. GitHub Actions build + déploie automatiquement (2-3 min)

### Vérifier que le backend tourne

```bash
ssh -i ta_cle.pem ubuntu@<IP_VM>
docker ps                    # Voir le conteneur
docker compose logs -f       # Voir les logs
```

### Arrêter / Redémarrer

```bash
cd /opt/leaks-backend
docker compose stop          # Arrêter
docker compose start         # Redémarrer
docker compose restart       # Redémarrer plus vite
```

### Sauvegarde des données H2

```bash
cd /opt/leaks-backend
tar -czf backup-$(date +%Y%m%d).tar.gz data/
```

---

## Configuration du frontend (APK)

Pour que l'APK communique avec le backend déployé, modifier l'URL de l'API dans le frontend :

```dart
// lib/config/api_config.dart
static const String apiBaseUrl = 'http://<IP_VM>:8080/api';
```

Puis rebuild l'APK :
```bash
cd frontend
flutter build apk --release
```

---

## Notes importantes

- **H2 en mode fichier** : Les données persistent dans `./data/` grâce au volume Docker
- **Redémarrage auto** : `restart: always` → le conteneur se relance après un reboot de la VM
- **n8n** : Continue de tourner avec PM2, aucun impact
- **Pas de SSL** pour l'instant → accès en HTTP sur l'IP publique
- **Pas de domaine** → utiliser l'IP directe
