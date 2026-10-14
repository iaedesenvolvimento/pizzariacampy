# Google Play checklist

- Confirmar `applicationId`: `com.pizzariacampy.app`.
- Criar keystore de produção fora do repositório e preencher `android/key.properties`.
- Incrementar `version` em `pubspec.yaml` a cada publicação.
- Configurar URL HTTPS da API com `--dart-define=API_BASE_URL=...`.
- Confirmar SMTP e endpoint HTTPS de recuperação de senha no ambiente de produção.
- Gerar `.aab` com `flutter build appbundle --release`.
- Revisar nome, ícone, splash, screenshots, classificação etária e política de privacidade no Play Console.
- Publicar primeiro em teste interno e validar login, checkout, pagamento manual e acompanhamento.

O iOS/App Store fica para uma etapa posterior, conforme o plano mestre.
