---
создал заметку: "2026-10-28"
---
### 502, преждевременное закрытие соединения до отправки ответа

Запрос `GET /` возвращает 200 ok, `GET /crash` возвращает 502 bad gateway.

В начало `do_GET()` в `app.py`, перед существующим `if self.path == "/":`, добавлено:

```
if self.path == "/crash":
    raise RuntimeError("Simulated backend failure.")
```

#### **Диагностика**

1. `curl -i --H 'Host: support.local' http://127.0.0.1/`, если он возвращает 200, значит бэкенд работает и слушает порт, ошибка возникает при `GET /crash`
2. Смотрим по журналу ошибок, почему nginx получал 502
```
upstream prematurely closed connection
while reading response header from upstream
```
Соединение было установлено, backend закрыл его, не начав отправлять заголовки. 
3. Подтверждаем ошибку по логам самого приложения `sudo journalctl -u support-app -n 25 --no-pager`

В журнале будет следующее:
```
File /home/user1/support-lab/app/app.py, line 12, in do_GET raise RuntimeError("Simaluted backend failure.")
RuntimeError: Simaluted backend failure.
```
По выводу можно локализировать причину

#### **Причина**

Необработанное исключение в `do_GET()`, соединение закрывается без ответа. Сервер продолжает работать и отдавать ответы.

#### **Восстановление**

Убрать блок с исключением + перезапуск сервиса

`sudo systemctl restart support-app.service`

#### **Проверка результата**

`curl -i -H 'Host: support.local' http://127.0.0.1/`

#### **Вывод**

Приложение может работать, но выдавать некорректные ответы на определенные запросы.
