# DevOps

## Ambientes

- `development`: `docker-compose.yml` com PostgreSQL local e migrations automáticas.
- `staging`: use `.env.staging.example` como base e execute a imagem publicada com uma base isolada.
- `production`: use `.env.production.example`, segredos externos e migrations em etapa controlada do deploy.

## Desenvolvimento local

```powershell
Copy-Item .env.development.example .env
docker compose up --build
```

A API fica em `http://localhost:8000`; health check em `/api/v1/health` e readiness em `/api/v1/ready`.

## Migrations

O entrypoint executa `alembic upgrade head` antes de iniciar a API. Em staging/produção, faça backup e confirme a migration antes de liberar tráfego.

## Backup

Com `pg_dump` instalado e `DATABASE_URL` definido:

```powershell
.\scripts\backup.ps1
```

Armazene os arquivos fora do host da aplicação, com retenção e criptografia definidos pela operação. Nunca versionar `.env` ou backups.

## Catálogo demonstrativo

Para preencher o ambiente local com produtos de teste:

```powershell
docker compose up --build -d
docker compose exec api python scripts/seed_demo.py
```

## Catálogo real

Preencha `catalog.real.example.json` com os dados oficiais e importe no ambiente local:

```powershell
docker compose up --build -d
docker compose cp catalog.real.json api:/app/catalog.real.json
docker compose exec api python scripts/import_catalog.py catalog.real.json
```

O importador atualiza registros pelo `slug` ou nome, pode ser executado novamente e não remove produtos existentes. Não execute `seed_demo.py` em staging ou produção.

## Primeiro administrador

Crie o usuário que poderá acessar os endpoints administrativos:

```powershell
docker compose up --build -d
docker compose exec api python scripts/create_admin.py "Nome do responsável" admin@pizzariacampy.com.br
```

O comando solicitará a senha sem gravá-la no histórico do script. Usuários registrados pelo aplicativo continuam com o papel `CUSTOMER`.
