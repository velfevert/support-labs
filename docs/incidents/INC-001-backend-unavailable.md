### 502, connection refused
 
 `http://support.local/` возвращает 502 bad gateway.

Сервис остановлен `sudo systemctl stop support-app.service`

#### **Диагностика**

1. Проверяем работу nginx, он должен возвращать 502 `curl -i -H 'Host: support.local' http://127.0.0.1/`
2. Смотрим журнал error.log, чтобы узнать причину 502 `tail -n 5 /var/log/nginx/error.log`, сообщение `connect() failed (111: Connection refused) while connecting to upstream` означает, что nginx получает RST от upstream при попытке подкючения
3. Проверяем состояние backend `systemctl status support-app.service` --> `inactive (dead)` = процесс остановлен
4. `sudo ss -lntp 'sport = :8080'` проверяем, слушает ли какое-нибудь приложение порт 8080

#### **Причина**

Сервис остановлен командой `systemctl stop`. На сокете 127.0.0.1:8080 нет процесса, который может принять соединение, и nginx формирует `502`. В реальном инциденте на этом шаге нужно выяснить, почему сервис остановился (`journalctl -u support-app`). В лабе причина известна.

#### **Восстановление**

`sudo systemctl start support-app.service`

#### **Проверка**

- Проверка на уровне systemd `systemctl status support-app.service`; `active (running)` - сервис запущен
- Проверка на уровне TCP `sudo ss -lntp 'sport = :8080'`; python процесс слушает порт 8080
- Проверка на уровне HTTP `curl -i -H 'Host: support.local' http://127.0.0.1/`; получен HTTP 200 и ответ Python-приложения.

#### **Вывод**

Одной из причин 502 Bad Gateway является то, что upstream отклоняет подключение (активно или из-за отсутствия процесса на нужном сокете)
