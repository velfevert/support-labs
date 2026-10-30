Лабы по администрированию Linux и диагностике неисправностей.

Создал два systemd-сервиса для bash-скрипта и python HTTP-сервером.

### systemd

- `heartbeat.service` — bash-скрипт, который каждые 4 секунды пишет PID и время. `Restart=on-failure`.
- `support-app.service` — Python HTTP-приложение на 127.0.0.1:8080. Запускается после network.target, перезапускается при завершении с ненулевым кодом.

Сервисы запускаются при загрузке системы через `multi-user.target`.

### nginx

**reverse proxy - `support.local`**

Слушает порт 80, принимает запросы и проксирует их на 127.0.0.1:8080 `proxy_pass http://127.0.0.1:8080`

Использует отдельный журнал `support-access.log` с пользовательским форматом `support`. Формат журнала: [log_format.conf](nginx/log-format.conf). Объявляется в блоке `http`, применяется только на хосте support.local.

Архитектура обратного прокси:
```
        :80            proxy_pass
Client ——————> Nginx ——————————————> 127.0.0.1:8080 (python)
```

**Статика - `static.local`**

static.local обслуживает небольшую HTML страницу с CSS. В лабе исходники [index.html](nginx/static-site/index.html) и [style.css](nginx/static-site/style.css) находились в домашнем каталоге и копировались в /var/www/static/.

- Редирект HTTP → HTTPS (`301 Moved Permanently`) и самоподписанный TLS-сертификат. Как создать и проверить: [tls-certificate](docs/runbooks/tls-certificate.md).
- Заголовки безопасности: X-Content-Type-Options: nosniff, X-Frame-Options: DENY, Content-Security-Policy: default-src 'self'; frame-ancestors 'none', Strict-Transport-Security: max-age=3600
- Кэширование CSS: `expires 1h`, gzip для CSS и JS: [cache-gzip](docs/notes/http-cache+gzip.md)
- Ограничение частоты запросов - rate limiting
- Ответ `404`, если файл не найден
- Файлы копируются в `/var/www/static/`. [static-permission](docs/runbooks/nginx-static-403-permissions.md)

### Структура репозитория

```
support-labs/
├── README.md
├── app/
│   └── app.py
├── linux/
│   └── systemd/
│       ├── heartbeat
│       ├── heartbeat.service
│       └── support-app.service
├── nginx/
│   ├── log-format.conf
│   ├── support-app.conf
│   ├── static-site.conf
│   └── static-site/
│       ├── index.html
│       └── style.css
└── docs/
    ├── incidents/
    │   ├── INC-001-backend-unavailable.md
    │   ├── INC-002-upstream-connection-closed.md
    │   ├── INC-003-upstream-timeout.md
    │   └── INC-004-port-conflict.md
    ├── runbooks/
    │   ├── nginx-static-403-permissions.md
    │   ├── restart-services.md
    │   └── tls-certificate.md
    └── notes/
        ├── http-cache+gzip.md
        └── nginx-static-403-permissions.md
```

### Быстрый старт

Репозиторий должен лежать в `/home/user1/support-labs`

| Файл в репозитории                                 | Куда на сервере                                          |
| -------------------------------------------------- | -------------------------------------------------------- |
| `linux/systemd/*.service`                          | `/etc/systemd/system/`                                   |
| `linux/systemd/heartbeat`                          | `/home/user1/bin/heartbeat`                              |
| `nginx/log-format.conf`                            | `/etc/nginx/conf.d/`                                     |
| `nginx/support-app.conf`, `nginx/static-site.conf` | `/etc/nginx/sites-available/`, ссылки в `sites-enabled/` |
| `nginx/static-site/*`                              | `/var/www/static/`                                       |

```
sudo systemctl daemon-reload
sudo systemctl start heartbeat.service support-app.service
sudo systemctl enable heartbeat.service support-app.service

sudo nginx -t && sudo systemctl reload nginx
```

### Проверка

`systemctl is-active heartbeat support-app`
`curl -i -H 'Host: support.local' http://127.0.0.1/`
`curl -i -H 'Host: static.local' http://127.0.0.1/` 
`curl -i --resolve static.local:443:127.0.0.1 --cacert /etc/nginx/ssl/static.local-new.crt https://static.local/`

### Инциденты

Имитировались различные сбои (остановка сервиса, временные правки `app.py` и конфигурации Nginx) и разбирались по журналам.

- [INC-001](docs/incidents/INC-001-backend-unavailable.md) `GET /` 502 Bad Gateway, connection refused
- [INC-002](docs/incidents/INC-002-upstream-connection-closed.md) ` GET /crash` 502 Bad Gateway, prematurely closed
- [INC-003](docs/incidents/INC-003-upstream-timeout.md) `GET /slow` 504 Gateway Timeout, upstream time out
- [INC-004](docs/incidents/INC-004-port-conflict.md) порт 8080 занят, Address already in use

### Примечания

- Unit-файлы содержат абсолютные пути и имя пользователя `user1`.
- Самоподписанный сертификат и приватный ключ не хранятся в репозитории (`.gitignore`) и создаются локально.
- `HSTS max-age=3600` выбран для тестовой среды лабы
- Тестовые обработчики `/crash` и `/slow` и `proxy_read_timeout 3s` добавлялись временно, в репозитории лежат рабочие версии, код для воспроизведения приведён в соответствующих INC-файлах.
