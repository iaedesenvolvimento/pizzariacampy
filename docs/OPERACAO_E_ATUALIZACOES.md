# Operação e atualizações

## Alterações sem recompilar o aplicativo

Estas informações ficam no backend e podem ser alteradas pelo painel administrativo:

- categorias, produtos, descrições e preços;
- imagens hospedadas no Cloudinary;
- tamanhos, sabores, bordas e adicionais;
- taxas, pedido mínimo, horários e zonas de entrega;
- cupons, pedidos e status operacionais.

Depois de salvar a alteração, o cliente recebe o novo conteúdo ao atualizar o catálogo ou reabrir o aplicativo.

## Alterações que exigem nova versão

É necessário compilar e publicar uma nova versão quando houver alteração em:

- telas, navegação ou componentes Flutter;
- regras que dependem do código instalado no celular;
- permissões Android, plugins ou integrações nativas;
- correções de segurança no aplicativo;
- novas funcionalidades que não existem no app atual.

## Publicação de uma nova versão

1. Atualize o código e execute `flutter analyze` e `flutter test`.
2. Incremente `version` e `versionCode` em `pubspec.yaml`.
3. Compile o `.aab` usando a mesma keystore da primeira publicação.
4. Envie o `.aab` para uma faixa interna da Google Play.
5. Teste a versão publicada antes de liberar para todos.

Nunca perca a keystore nem altere o `applicationId`. Sem a mesma assinatura, a Google Play não aceitará atualizações.

## Ambiente de produção

- O aplicativo deve usar uma URL pública HTTPS, nunca `localhost` ou IP da rede local.
- A API e o banco devem ter backups e migrations versionadas.
- Segredos SMTP, Cloudinary, JWT e banco ficam somente no servidor.
- A API deve manter compatibilidade com versões anteriores durante a distribuição gradual.

