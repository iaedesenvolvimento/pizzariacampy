# Pizzaria Campy Mobile

Aplicativo Flutter da Pizzaria Campy, inicialmente direcionado para Android e preparado para iOS.

## Pré-requisitos

- Flutter SDK compatível com Dart 3.5 ou superior.
- Android SDK para executar no Android.
- Xcode e CocoaPods para executar no iOS.

## Criar as plataformas

Como o Flutter SDK não estava disponível durante a criação desta base, gere os diretórios de plataforma a partir desta pasta quando ele estiver instalado:

```powershell
flutter create --platforms=android,ios .
```

Revise o `applicationId`, bundle identifier, nome do app e permissões antes de publicar.

## Executar

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Para produção, o valor padrão aponta para `https://pizzariacampy.onrender.com/api/v1`. Em desenvolvimento, informe a API local com `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` ou com o endereço da máquina no dispositivo físico.

## Estrutura

```text
lib/
  core/          # configuração, rede, armazenamento e erros
  features/      # módulos por fluxo do produto
  routes/        # navegação
  shared/        # componentes reutilizáveis
  theme/         # tema visual
```

Autenticação, cardápio, personalização, carrinho, checkout, acompanhamento e painel administrativo estão implementados em fases incrementais. Consulte `../docs/STATUS_PROJETO.md` para o estado atual e as pendências.
