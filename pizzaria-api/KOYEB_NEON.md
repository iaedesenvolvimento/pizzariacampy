# Deploy no Koyeb com PostgreSQL Neon

Esta configuração usa o `Dockerfile` existente da API. O container executa `alembic upgrade head` antes de iniciar o Uvicorn e usa a variável `PORT` fornecida pelo Koyeb.

## 1. Criar o banco no Neon

Crie um projeto PostgreSQL no Neon e copie a conexão pooled. No Koyeb, configure `DATABASE_URL` no formato:

```text
postgresql+asyncpg://USUARIO:SENHA@HOST_POOLER.neon.tech/NOME_BANCO?ssl=require
```

A API também aceita a URL padrão `postgresql://...?...sslmode=require` do Neon e a converte internamente para o driver assíncrono.

## 2. Criar o serviço no Koyeb

No painel do Koyeb:

1. Crie um Web Service a partir do repositório GitHub.
2. Selecione o builder `Dockerfile`.
3. Use `pizzaria-api` como diretório de trabalho.
4. Use `Dockerfile` como arquivo de build.
5. Exponha a porta `8000` como HTTP.
6. Configure o health check HTTP em `/api/v1/health`.
7. Selecione a instância `free` para testes.

As variáveis necessárias estão em `.env.koyeb.example`. Cadastre os valores reais como secrets no painel; não copie o arquivo `.env` para o repositório.

## 3. Variáveis obrigatórias

- `DATABASE_URL`: conexão pooled do Neon com SSL.
- `SECRET_KEY`: valor aleatório com pelo menos 32 caracteres.
- `PUBLIC_APP_URL`: URL pública do serviço Koyeb.
- `PORT`: `8000`, se não quiser usar o valor automático do Koyeb.

Para recuperação de senha, configure também as variáveis `SMTP_*`. Para imagens oficiais, configure as variáveis `CLOUDINARY_*`.

## 4. Validação

Depois do deploy, valide:

```text
GET https://SEU_DOMINIO_KOYEB/api/v1/health
GET https://SEU_DOMINIO_KOYEB/api/v1/ready
```

O endpoint `ready` só deve retornar sucesso depois que as migrations conseguirem acessar o Neon.

## 5. APK

Depois de confirmar a URL pública do Koyeb, gere o APK com:

```powershell
flutter build apk --release --target-platform android-arm64 --dart-define=API_BASE_URL=https://SEU_DOMINIO_KOYEB/api/v1
```
