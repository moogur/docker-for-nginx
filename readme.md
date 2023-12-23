# Докер образ веб сервера nginx

Докер сборка nginx, это веб-сервер и почтовый прокси-сервер

## Репозиторий nginx

- <https://github.com/nginx/nginx>

### Mодули включеные в сборку (установка с помощью директивы `load_module`)

- [brotli](https://github.com/google/ngx_brotli)
- [substitutions](https://github.com/yaoweibin/ngx_http_substitutions_filter_module)

### Docker container

- <https://github.com/nginxinc/docker-nginx>

## Переменные

- LOCAL_DATABASES - если `false` то скачивает базы mixmind из интернета
