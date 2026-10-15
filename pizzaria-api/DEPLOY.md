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

## Importação do catálogo no Render

Depois do primeiro deploy da imagem que contém `catalogo-real.json`, configure `IMPORT_CATALOG_ON_STARTUP=true` nas variáveis de ambiente do serviço Render e faça um novo deploy. O entrypoint executará a importação depois das migrations, sem exigir acesso ao Shell.

Depois que os produtos aparecerem, altere a variável para `false` e faça outro deploy. Se o Shell estiver disponível, a importação manual equivalente é:

```bash
python scripts/import_catalog.py catalogo-real.json --dry-run
python scripts/import_catalog.py catalogo-real.json
```

O primeiro comando valida o arquivo sem gravar dados. O segundo cadastra ou atualiza o catálogo oficial no PostgreSQL configurado em `DATABASE_URL`. Depois, confirme `GET /api/v1/categories` e `GET /api/v1/products`.

## Importação das imagens no Render

A configuração do Cloudinary não preenche automaticamente o campo `image_url` dos produtos. Para importar as imagens sem usar o Shell:

1. Faça o deploy da imagem que contém `catalog-images-manifest.json` e `assets/catalog-images`.
2. No Render, mantenha as variáveis `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY` e `CLOUDINARY_API_SECRET` configuradas.
3. Adicione `IMPORT_PRODUCT_IMAGES_ON_STARTUP=true` e faça um deploy manual.
4. Aguarde o log `Produtos atualizados: ...` e confirme `GET /api/v1/products`.
5. Altere `IMPORT_PRODUCT_IMAGES_ON_STARTUP` para `false` e faça novo deploy, para não reenviar as imagens a cada reinício.

O processo é idempotente: ele sobrescreve os mesmos arquivos no Cloudinary e atualiza os produtos pelo `slug`.

## Rollback

- Preserve a imagem anterior e o backup antes do deploy.
- Reative a imagem anterior somente se a migration for compatível.
- Para migration destrutiva, restaure o backup em uma instância isolada e valide antes de substituir o banco.
