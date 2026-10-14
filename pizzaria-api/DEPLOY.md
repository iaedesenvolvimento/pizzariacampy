# Deploy

## Topologia

- PostgreSQL usa volume persistente e não é exposto publicamente.
- `migrate` executa `alembic upgrade head` como etapa separada.
- `api` só inicia depois da migration concluída.
- Caddy termina HTTPS e encaminha para a API.
- O painel administrativo está integrado ao aplicativo Flutter e usa a mesma API; a publicação mobile ocorre na Fase 31.

## Pré-requisitos

1. Servidor dedicado para produção; nunca reutilizar o banco de desenvolvimento.
2. DNS `APP_DOMAIN` apontando para o servidor.
3. Docker Compose instalado.
4. Arquivo `.env` preenchido por secret manager ou mecanismo equivalente.
5. SMTP de produção configurado para recuperação de senha.
6. Backup restaurável confirmado antes de migrations.

## Execução

```powershell
Copy-Item .env.production.deploy.example .env
# editar .env com valores reais e nunca versionar o arquivo
.\scripts\deploy-production.ps1
```

Caddy solicita e renova o certificado HTTPS automaticamente quando o DNS e as portas 80/443 estiverem corretos.

## Rollback

- Preserve a imagem anterior e o backup antes do deploy.
- Reative a imagem anterior somente se a migration for compatível.
- Para migration destrutiva, restaure o backup em uma instância isolada e valide antes de substituir o banco.
