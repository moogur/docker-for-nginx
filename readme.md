# Докер образ веб-сервера nginx

Сборка `nginx` на базе официального образа `nginx:<версия>-alpine-slim` с дополнительными
**динамическими модулями**, которых нет в официальном образе: brotli, substitutions, zstd, headers-more.

Модули компилируются в отдельной стадии сборки из исходников nginx той же версии и складываются
в `/usr/lib/nginx/additional-modules`. Подключаются директивой `load_module` — по умолчанию ни один
из них не активен, образ ведёт себя как обычный `nginx:alpine-slim`.

## Версии

Задаются в [`Dockerfile`](Dockerfile) через `ARG` (сейчас — nginx `1.31.5`, alpine `3.24`):

| `ARG` | Что задаёт |
| --- | --- |
| `NGINX_VERSION` | Версия nginx: исходники для сборки модулей и тег базового образа `nginx:<версия>-alpine-slim` |
| `ALPINE_VERSION` | Alpine стадии сборки |

`ALPINE_VERSION` должен совпадать с alpine, на котором собран базовый образ: динамический модуль
линкуется с musl и openssl стадии сборки, и при расхождении версий nginx откажется его загружать.
Проверить актуальное значение — в первой строке `FROM alpine:...`
[Dockerfile официального образа][docker-nginx-dockerfile].

## Модули

Файлы лежат в `/usr/lib/nginx/additional-modules`:

- **brotli** — сжатие Brotli на лету и раздача заранее сжатых `.br`.
  Файлы: `ngx_http_brotli_filter_module.so`, `ngx_http_brotli_static_module.so`.
  Исходники: <https://github.com/google/ngx_brotli>
- **substitutions** — замена текста в теле ответа по регулярным выражениям.
  Файл: `ngx_http_subs_filter_module.so`.
  Исходники: <https://github.com/yaoweibin/ngx_http_substitutions_filter_module>
- **zstd** — сжатие Zstandard на лету и раздача заранее сжатых `.zst`.
  Файлы: `ngx_http_zstd_filter_module.so`, `ngx_http_zstd_static_module.so`.
  Исходники: <https://github.com/tokers/zstd-nginx-module>
- **headers_more** — гибкое управление заголовками запроса и ответа.
  Файл: `ngx_http_headers_more_filter_module.so`.
  Исходники: <https://github.com/openresty/headers-more-nginx-module>

`brotli` собирается с пина коммита (см. `git checkout` в [`Dockerfile`](Dockerfile)), остальные — с `master`.

## Образ

Публикуется в GitHub Packages:

```text
docker.pkg.github.com/<владелец>/docker-for-nginx/docker-for-nginx:<тег>
```

| Тег | Что означает |
| --- | --- |
| `v1.1.1` | Конкретный релиз, никогда не меняется |
| `v1.1` | Последний патч минорной версии |
| `v1` | Последний релиз мажорной версии |
| `latest` | Последний релиз вообще |

Подвижные `v1` и `v1.1` перезаписываются каждым новым релизом: закрепляйтесь на них, если хотите
получать обновления автоматически, и на `v1.1.1` — если нужна воспроизводимость.

## Использование

Как базовый образ:

```dockerfile
FROM docker.pkg.github.com/moogur/docker-for-nginx/docker-for-nginx:v1

COPY nginx.conf /etc/nginx/nginx.conf
```

Подключение модулей в `nginx.conf` — `load_module` только на верхнем уровне, до блока `http`:

```nginx
load_module /usr/lib/nginx/additional-modules/ngx_http_brotli_filter_module.so;
load_module /usr/lib/nginx/additional-modules/ngx_http_brotli_static_module.so;
load_module /usr/lib/nginx/additional-modules/ngx_http_headers_more_filter_module.so;

events {}

http {
  brotli on;
  brotli_types text/plain text/css application/javascript application/json image/svg+xml;
  brotli_static on;

  more_set_headers "X-Powered-By: nginx";

  # ...
}
```

Директивы каждого модуля — в его README (ссылки в разделе «Модули»).

## Релиз

Сборка и публикация образа идут по пушу git-тега формата `vX.Y.Z`
([`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)):

```bash
git tag v1.0.1
git push origin v1.0.1
```

Workflow вызывает `deploy_for_docker_container` из [all-workflows](https://github.com/moogur/all-workflows)
с `format_mode: 'semver'` — он и раскладывает один тег в `v1.0.1`, `v1.0`, `v1`, `latest`.
Пуш в `master` образ не собирает: там работает только интеграция с Kanboard
([`.github/workflows/push.yml`](.github/workflows/push.yml)).

Теги-даты (`14.03.2026` и раньше) — прежний формат, оставлены в истории и под триггер деплоя
больше не подходят.

## Разработка

```bash
npm install                                   # husky и git-хуки
docker build -t docker-for-nginx:local .      # локальная сборка (компиляция модулей — несколько минут)
```

Сообщения коммитов проверяет хук [`.husky/commit-msg`](.husky/commit-msg), валидируется только заголовок:

```text
[DOC-<номер>] <type>(<scope>): <subject>
```

Например: `[DOC-566] feature(version): update nginx to 1.31.5`. Допустимые `type`:
`feature`, `bugfix`, `ci`, `config`, `refactor`, `test`, `docs`; `scope` и `subject` — нижний регистр,
`subject` не длиннее 125 символов.

## Ссылки

- Исходники nginx — <https://github.com/nginx/nginx>
- Официальный образ nginx — <https://github.com/nginx/docker-nginx>
- Версии nginx (mainline / stable) — <https://nginx.org/en/download.html>

[docker-nginx-dockerfile]: https://github.com/nginx/docker-nginx/blob/master/mainline/alpine-slim/Dockerfile
