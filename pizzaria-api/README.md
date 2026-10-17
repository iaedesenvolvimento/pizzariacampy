# Pizzaria Campy API

Backend FastAPI da Pizzaria Campy.

## Configuração local

1. Crie e ative um ambiente virtual com Python 3.11 ou superior.
2. Instale as dependências do projeto:

```powershell
pip install -e ".[dev]"
```

3. Copie `.env.example` para `.env` e ajuste `DATABASE_URL` e `SECRET_KEY`.
4. Inicie a API:

```powershell
uvicorn app.main:app --reload
```

## Verificação

- `GET /api/v1/health`: verifica a aplicação sem depender do banco.
- `GET /api/v1/ready`: verifica a conexão com o PostgreSQL.
- `/docs`: documentação OpenAPI local.

## Migrations

As migrations usam Alembic e devem ser executadas a partir desta pasta:

```powershell
alembic upgrade head
```

As tabelas de autenticação, catálogo, pedidos, pagamentos, zonas, horários e cupons estão versionadas em `migrations/versions`. Execute `alembic upgrade head` antes de iniciar a API.

### Catálogo normalizado v2

O catálogo v2 separa pizzas configuráveis, produtos simples e combos. Gere o
arquivo a partir do catálogo legado sem alterar o banco:

```powershell
python scripts/build_catalog_v2.py catalogo-real.json catalogo-campy-v2.json
```

Valide a estrutura do arquivo antes de importar:

```powershell
python scripts/seed_catalog_v2.py catalogo-campy-v2.json --dry-run
```

O importador é idempotente e não publica combos cuja composição ainda exige
revisão manual. A importação real deve ser feita somente após validar o arquivo
e executar as migrations no banco local:

```powershell
alembic upgrade head
python scripts/seed_catalog_v2.py catalogo-campy-v2.json
```

## Importação do catálogo oficial

O arquivo JSON do cardápio deve conter somente dados conferidos. Antes de gravar no banco, execute o modo de validação:

```powershell
python scripts/import_catalog.py caminho/catalogo.json --dry-run
```

O validador rejeita placeholders, slugs inválidos ou duplicados, preços negativos, tamanhos sem preço, quantidade de fatias diferente de 8 e URLs de exemplo. Após a conferência, remova `--dry-run` para importar ou atualizar os registros pelo slug.

### Planilha oficial

Para converter a planilha `.xlsx` entregue pela pizzaria em JSON:

```powershell
python scripts/build_catalog_from_xlsx.py caminho/cardapio_pizzaria_campy.xlsx catalogo-real.json
python scripts/import_catalog.py catalogo-real.json --dry-run
python scripts/import_catalog.py catalogo-real.json
```

O conversor gera `catalogo-real.skipped.json` com as linhas sem preço. Esses valores devem ser preenchidos antes de cadastrar os itens pendentes; nenhum preço é inventado automaticamente.

### Recuperação de senha

Defina `SMTP_HOST`, `SMTP_FROM_EMAIL` e as credenciais SMTP no ambiente de produção. O endpoint `POST /auth/password-recovery` responde de forma genérica para não revelar se um e-mail existe; o token expira conforme `PASSWORD_RESET_EXPIRE_MINUTES` e só pode ser usado uma vez.

### Imagens do catálogo

O painel administrativo envia imagens de produtos para o Cloudinary por meio do endpoint autenticado `POST /api/v1/admin/images/upload`. Configure `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY` e `CLOUDINARY_API_SECRET` no ambiente da API. A chave secreta nunca deve ser colocada no aplicativo Flutter.

Para preparar imagens em lote a partir da planilha oficial:

```powershell
python scripts/build_image_manifest.py caminho/cardapio_pizzaria_campy.xlsx catalog-images-manifest.json --assets-dir assets/catalog-images
python scripts/import_product_images.py catalog-images-manifest.json --assets-dir assets/catalog-images --dry-run
```

O manifesto cria um arquivo esperado por slug, além de um prompt padronizado para cada produto. Coloque as imagens JPG, PNG ou WebP em `assets/catalog-images`, usando os nomes indicados no manifesto. Depois de revisar o resultado do `dry-run`, execute o importador dentro do serviço `api` para enviar ao Cloudinary e atualizar os produtos:

```powershell
docker compose exec api python scripts/import_product_images.py /app/catalog-images-manifest.json --assets-dir /app/assets/catalog-images
```

O processo é incremental: imagens ausentes são apenas listadas e produtos já atualizados podem ser reenviados com segurança. As imagens ficam no Cloudinary e não são incorporadas ao APK.

### Geração automática com Leonardo AI

O manifesto também pode ser usado para gerar imagens ilustrativas em lote. A API Leonardo exige uma chave própria e créditos separados do plano web; nunca coloque a chave no Flutter ou em arquivos versionados.

Teste primeiro com três produtos:

```powershell
$env:LEONARDO_API_KEY = "sua-chave-temporaria"
python scripts/generate_product_images.py catalog-images-manifest.json --output-dir assets/catalog-images --limit 3 --dry-run
python scripts/generate_product_images.py catalog-images-manifest.json --output-dir assets/catalog-images --limit 3
```

Depois de revisar as imagens, rode o importador Cloudinary. Para gerar o restante, aumente `--limit` ou remova essa opção. Imagens de marcas devem ser obtidas de fontes autorizadas, não geradas artificialmente.
