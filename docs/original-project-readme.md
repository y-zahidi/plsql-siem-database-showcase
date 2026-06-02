# Projet EFM — SIEM v2 (Mini-Plateforme de gestion d'événements de sécurité)

> **Module : Bases de Données Avancées**
> **Filière : Génie Informatique — Spécialisation Cybersécurité**

---

## 🎯 Sujet réel

Centraliser et analyser les événements de sécurité (alertes IDS, logs firewall,
échecs SSH, injections SQL, malware…) provenant d'un parc d'équipements.
C'est exactement ce que font des outils comme **Splunk**, **ELK Stack**, ou **Wazuh**
en production.

---

## 🏗️ Architecture

```
┌────────────────┐       ┌──────────────────┐       ┌─────────────────┐
│  PostgreSQL    │       │   Python (ETL +  │       │    MongoDB      │
│  (BD maître)   │ ────► │  streaming temps │ ────► │ (BD d'affichage)│
│  + Triggers    │ NOTIFY│      réel)       │       │  + Aggregations │
│  + Procédures  │ ◄──── │                  │       │                 │
│  + pgcrypto    │       └──────────────────┘       └────────┬────────┘
└────────────────┘                                            │
                                                              ▼
                                              ┌───────────────────────────┐
                                              │   Streamlit Dashboard     │
                                              │ http://localhost:8501     │
                                              ├───────────────────────────┤
                                              │   Mongo Express           │
                                              │ http://localhost:8081     │
                                              └───────────────────────────┘
```

Voir le détail dans [`diagrammes/architecture.png`](diagrammes/architecture.png)
et le **MCD complet** dans [`diagrammes/mcd.png`](diagrammes/mcd.png).

---

## 📁 Contenu du projet

| Fichier                          | Description                                                     |
|----------------------------------|-----------------------------------------------------------------|
| `01_schema.sql`                  | Schéma : 6 tables, séquences, contraintes, **INET, JSONB**, index (B-tree, partiel, **GIN**, **trigram**), extensions `pgcrypto`/`pg_trgm` |
| `02_fonctions.sql`               | 6 fonctions PL/pgSQL (calcul score, niveau de risque, **hash audit chaîné pgcrypto**) |
| `03_triggers.sql`                | 4 triggers (BEFORE/AFTER INSERT/UPDATE) + `pg_notify` pour le streaming |
| `04_procedures.sql`              | 5 procédures stockées (curseurs LOOP, FOR, WHILE, EXCEPTION) |
| `05_vues.sql`                    | 4 vues normales + **1 vue matérialisée** `mv_dashboard_soc` |
| `06_donnees_test.sql`            | Jeu de données de base (16 alertes avec payload JSONB) |
| `seed_realistic.py`              | Génère un volume réaliste (~350 alertes sur 7 jours) pour le dashboard |
| `07_python_etl.py`               | Script Python ETL (PostgreSQL → MongoDB), avec env vars + try/except |
| `07b_streaming.py`               | **Streaming temps réel** via PostgreSQL `LISTEN/NOTIFY` (NEXT LEVEL) |
| `08_mongodb_requetes.js`         | Requêtes & agrégations MongoDB (incluant `$facet`, `$lookup`, `$bucket`, `$unwind`) |
| `10_dashboard.py`                | **SecOps Console** — dashboard Web style SOC professionnel (Streamlit) |
| `.streamlit/config.toml`         | Thème sombre + chrome Streamlit masqué |
| `99_explain_analyze.sql`         | Démonstration de l'utilité des index (`EXPLAIN ANALYZE`) |
| `demo.sql`                       | 8 requêtes "wow" prêtes à montrer en soutenance |
| `RAPPORT_COMPARAISON_PG_MONGO.md`| Comparaison PostgreSQL vs MongoDB (chapitre du rapport) |
| `09_plan_rapport.md`             | Plan détaillé du rapport académique |
| `requirements.txt`               | Dépendances Python (psycopg2, pymongo, streamlit, plotly, pandas) |
| `docker-compose.yml`             | Orchestre PostgreSQL 16 + MongoDB 7 + Mongo Express |
| `setup.ps1` / `setup.sh`         | Installation automatisée (Windows / Linux/Mac) |
| `diagrammes/`                    | MCD + diagramme d'architecture (PNG) |

---

## 🚀 Démarrage rapide

### Prérequis
- Docker Desktop
- Python 3.10+

### Installation automatique

**Windows :**
```powershell
.\setup.ps1
```

**Linux / Mac :**
```bash
chmod +x setup.sh && ./setup.sh
```

Le script :
1. Démarre PostgreSQL + MongoDB + Mongo Express via Docker
2. Charge tous les fichiers SQL dans l'ordre
3. Crée un environnement Python virtuel
4. Installe les dépendances depuis `requirements.txt`
5. Exécute le script ETL Python

### Charger un volume de données réaliste (recommandé pour le dashboard)

```bash
python seed_realistic.py --jours 7 --nb 350 --clean
python 07_python_etl.py
```

### Lancement du dashboard Web

```bash
streamlit run 10_dashboard.py
```

Puis ouvrir **http://localhost:8501**.

### Lancement du streaming temps réel

```bash
python 07b_streaming.py
```

Tester en parallèle (autre terminal) :
```bash
docker exec -it siem-postgres psql -U postgres -d siem_db -c \
  "INSERT INTO alerte(id_equipement,id_regle,source_ip,port) VALUES (1,1,'8.8.8.8',22);"
```
→ Le streaming affiche l'événement en moins d'une seconde et met à jour MongoDB.

### Accès direct

| Service        | URL / commande                                                |
|----------------|---------------------------------------------------------------|
| PostgreSQL     | `psql -h localhost -p 5433 -U postgres -d siem_db` (port publié par Docker ; voir `docker-compose.yml`) |
| MongoDB        | `mongosh mongodb://localhost:27017/siem_dashboard`            |
| Mongo Express  | http://localhost:8081 (admin / admin)                         |
| **Dashboard**  | **http://localhost:8501**                                     |

---

## 📚 Concepts du cours couverts

### PostgreSQL
- ✅ Séquences (6) avec auto-incrément
- ✅ Contraintes : `PRIMARY KEY`, `UNIQUE`, `NOT NULL`, `CHECK`, `FOREIGN KEY` avec `ON DELETE CASCADE/RESTRICT/SET NULL`
- ✅ Cohérence temporelle (`CHECK (date_resolution >= date_creation)`)
- ✅ Types avancés : `INET` (IP native), `JSONB` (document)
- ✅ Index : simple, composite, **partiel**, **GIN sur JSONB**, **trigram (pg_trgm)**
- ✅ Fonctions PL/pgSQL : `IF/ELSIF`, `CASE`, `RETURN TABLE`
- ✅ Triggers : `BEFORE INSERT`, `AFTER INSERT`, `AFTER UPDATE/DELETE`
- ✅ Procédures stockées : `LOOP` + `FETCH`, `FOR`, `WHILE`, `EXCEPTION WHEN OTHERS`
- ✅ Curseurs : `OPEN`, `FETCH`, `EXIT WHEN NOT FOUND`, `CLOSE`
- ✅ Vues : 4 vues classiques
- ✅ **Vue matérialisée** + `REFRESH MATERIALIZED VIEW CONCURRENTLY`
- ✅ **`pgcrypto`** : SHA256, signature de chaîne d'audit (type blockchain)
- ✅ **`LISTEN/NOTIFY`** : pub/sub natif PostgreSQL pour le streaming
- ✅ `EXPLAIN ANALYZE` : démonstration de l'usage des index

### MongoDB
- ✅ CRUD : `find()`, `insertMany()`, `updateMany()`, `deleteMany()`
- ✅ Opérateurs : `$gt`, `$lt`, `$ne`, `$or`, `$in`, `$regex`
- ✅ Documents imbriqués (sous-documents `source`, `equipement`, `regle`, `payload`)
- ✅ Recherche dans le JSON imbriqué (`payload.url`)
- ✅ Tri / projection / limite
- ✅ **Agrégations** : `$group`, `$match`, `$sort`, `$count`, `$sum`, `$avg`, `$max`
- ✅ **`$dateToString`** : timeseries
- ✅ **`$facet`** : multi-pipeline en une seule requête
- ✅ **`$lookup`** : jointures NoSQL
- ✅ **`$bucket`** : segmentation par tranches
- ✅ **`$unwind`** : éclatement de tableaux
- ✅ Index : simple, composite, sur sous-document

### Python
- ✅ `psycopg2` (PostgreSQL) + `pymongo` (MongoDB)
- ✅ Variables d'environnement (`os.getenv` + `python-dotenv`)
- ✅ Gestion d'erreurs (`try/except` avec messages clairs)
- ✅ ETL en batch (`07_python_etl.py`)
- ✅ **Streaming temps réel** (`07b_streaming.py` via `LISTEN/NOTIFY`)
- ✅ Dashboard Web (`10_dashboard.py` via Streamlit + Plotly)

---

## 🎓 Pour la soutenance

1. **Slides** (à préparer, voir `09_plan_rapport.md`)
2. **Démo live** (~5 min) :
   1. `docker compose up -d` → infrastructure prête
   2. Charger les 6 SQL → schéma + données
   3. Montrer pgAdmin / `\d alerte` → INET, JSONB, index
   4. Lancer `07_python_etl.py` → ETL
   5. Lancer `streamlit run 10_dashboard.py` → **UI Web**
   6. Insérer une alerte en SQL → la voir apparaître dans le dashboard via le streaming
3. **Requêtes "wow"** : voir `demo.sql`
4. **Audit signé** : `SELECT verifier_integrite_audit();` → 0 = audit non altéré

---

## 🛠️ Nettoyage

```bash
docker compose down -v   # Supprime aussi les volumes Docker
```

ou sur Windows :
```powershell
.\teardown.ps1
```

---

## 👤 Auteur

**Yassir** — Génie Informatique, spécialisation Cybersécurité.
Projet EFM Bases de Données Avancées.
