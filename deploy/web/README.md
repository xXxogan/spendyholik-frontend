# Развёртывание SpendyHolik Web

Публичный адрес Web — `https://spendyholik.duckdns.org`. Flutter обращается к API по `https://api.spendyholik.duckdns.org/api/v1/`. Оба домена указывают на один сервер. Манифест использует namespace `spendyholik`, класс `traefik` и `ClusterIssuer` `letsencrypt-prod` из настройки бэкенда.

## Сборка

Команды запускаются из корня Flutter-проекта. Нужна архитектура сервера. Ниже пример для `amd64`.

```sh
flutter pub get
flutter gen-l10n
dart run build_runner build
flutter build web --release --no-web-resources-cdn
docker buildx build --load --platform linux/amd64 \
  -f deploy/web/Dockerfile -t spendyholik-web:2026-11-22.2 .
docker save -o /tmp/spendyholik-web.tar spendyholik-web:2026-11-22.2
```

Для `arm64` поменяйте платформу сборки. Для следующего релиза используйте новый тег в командах сборки и в `kubernetes.yaml`. Для одного узла k3s образ можно передать архивом и импортировать в containerd без публикации в реестре.

## Политика обработки данных

Приложение читает документ по `https://spendyholik.duckdns.org/privacy-policy.md`. Явно передайте утверждённый файл на сервер и загрузите его в ConfigMap. Текст и реквизиты оператора хранятся на сервере.

```sh
sudo k3s kubectl -n spendyholik create configmap spendyholik-web-policy \
  --from-file=privacy_policy_ru.md=/secure/path/privacy-policy.md \
  --dry-run=client -o yaml | sudo k3s kubectl apply -f -
sudo k3s kubectl -n spendyholik rollout restart deployment/spendyholik-web
sudo k3s kubectl -n spendyholik rollout status deployment/spendyholik-web
```

Для первой установки создайте ConfigMap до Deployment. Перезапуск нужен при дальнейших изменениях документа, поскольку он монтируется как отдельный файл.

## Автообновление Web

Workflow `.github/workflows/web.yml` запускается после пуша в `main`. Он генерирует код, запускает анализатор и тесты, собирает образ и передаёт его по SSH. Версия образа и `/deploy-revision.txt` соответствуют SHA коммита. Сервер проверяет готовность, опубликованную версию и текст политики, при сбое возвращает прежний образ. Новые настройки Ingress и Deployment из манифеста применяются отдельно.

Для настройки используйте отдельный ключ Actions. На сервере `deploy/web/server-update.sh` устанавливается от root как `/usr/local/sbin/spendyholik-web-deploy`. Строка этого ключа в `authorized_keys` начинается с `restrict,command="/usr/local/sbin/spendyholik-web-deploy"`. В GitHub задаются переменные `WEB_SSH_HOST`, `WEB_SSH_KNOWN_HOSTS` с проверенным ключом сервера и Actions secret `WEB_SSH_KEY` с закрытым ключом. Workflow бэкенда остаётся в его репозитории.

## Выкладка

1. На сервере проверьте существующие правила Ingress в namespace `spendyholik`. Действующий `spendyholik-backend-api-host` обслуживает только `api.spendyholik.duckdns.org`. В серверных values бэкенда выставлено `ingress.enabled: false`, чтобы Helm не создавал второй Ingress для основного домена. В `env.CORS_ALLOWED_ORIGINS` разрешён `https://spendyholik.duckdns.org`.
2. При изменении настроек бэкенда примените их его штатным Helm-обновлением. Проверьте ответ `200` по `https://api.spendyholik.duckdns.org/health/`.
3. Передайте архив и `kubernetes.yaml` на сервер. Выполните команды на сервере в каталоге с этими файлами.

   ```sh
   sudo k3s ctr images import --platform linux/amd64 spendyholik-web.tar
   sudo k3s kubectl apply --dry-run=server -f kubernetes.yaml
   sudo k3s kubectl apply -f kubernetes.yaml
   sudo k3s kubectl -n spendyholik rollout status deployment/spendyholik-web
   sudo k3s kubectl -n spendyholik wait --for=condition=Ready certificate/spendyholik-web-tls --timeout=180s
   ```

4. Проверьте `https://spendyholik.duckdns.org/`, прямую ссылку `/#/privacy` и `flutter_bootstrap.js`. На основном домене `/health/` должен вернуть `404`, на API-домене — `200`. Проверьте CORS с Web-origin и пройдите регистрацию, подтверждение почты, вход и обновление страницы.

Если проверка новой версии Web не прошла, повторно примените предыдущий манифест с сохранённым тегом образа. Для первого выката можно снять Ingress фронтенда, оставив API на отдельном домене.
