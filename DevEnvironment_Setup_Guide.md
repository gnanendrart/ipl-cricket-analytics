# Development Environment Setup

**Machine:** MacBook (Apple Silicon M1/M2)
**OS:** macOS

---

## Requirements

| Tool | Purpose |
|---|---|
| PostgreSQL 15 | Database engine |
| psql | Load data and run queries from Terminal |
| VS Code | Code editor |
| SQLTools + PostgreSQL Driver | Run SQL inside VS Code |
| Anaconda (Python 3.11) | Python environment |
| psycopg2-binary | Connect Python to PostgreSQL |

---

## PostgreSQL Setup

```bash
brew install postgresql@15
echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
brew services start postgresql@15
createdb $(whoami)
```

Create the project database:

```bash
psql -c "CREATE DATABASE ipl_cricket;"
```

---

## Load the Dataset

Place `matches.csv` and `deliveries.csv` in your project folder, then load:

```bash
psql ipl_cricket -c "\copy matches FROM 'matches.csv' CSV HEADER;"
psql ipl_cricket -c "\copy deliveries FROM 'deliveries.csv' CSV HEADER;"
```

---

## VS Code SQLTools Connection

1. Install extensions:
```bash
code --install-extension mtxr.sqltools
code --install-extension mtxr.sqltools-driver-pg
```

2. Add connection via `Cmd+Shift+P` → SQLTools: Add New Connection:
   - Host: `localhost`
   - Port: `5432`
   - Database: `ipl_cricket`
   - Username: your Mac username (`whoami`)
   - Password: leave empty

3. Run queries by highlighting SQL and pressing `Cmd+E Cmd+E`

> **Note:** Do not install the MSSQL extension -- it conflicts with SQLTools and intercepts the run command for `.sql` files.

---

## Daily Workflow

```bash
cd ~/data-projects
conda activate data-eng
code .
```
