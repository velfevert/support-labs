---
создал заметку: "2026-10-28"
---
### 504, upstream не отвечает вовремя

`GET /slow` возвращает 504 gateway timeout

1. В app.py добавлена обработка `/slow`: приложение выполняет `time.sleep(10)`, затем отправляет обычный ответ 200.
2. В блоке `server` на хосте support.local объявлена директива `proxy_read_timeout 3s;`, которая задает таймаут на получение ответа

#### **Диагностика**

1. Первый запрос через nginx `curl -i -H 'Host: support.local' http://127.0.0.1/slow` возвращает 504 примерно через 3 секунды
 2. Запрос к бэкенду напрямую `curl -i http://127.0.0.1:8080/slow`, возвращает 200 где-то через 10 секунд, скорее всего задержка возникает в самом приложении, а не на пути между nginx и upstream
3. Проверяем error.log `tail -n 5 /var/log/nginx/error.log` 
   ```
   upstream timed out (110: Connection timed out) while reading response header from upstream,
   upstream: "http://127.0.0.1:8080/slow"
   ```
nginx превысил время ожидания заголовков ответа от upstream

В реальном инциденте такой таймаут может означать один долгий запрос, перегрузку большим числом запросов или проблему с сетью.

#### **Причина**

Бэкенд не успевает отдать ответ в пределах `proxy_read_timeout`, nginx инициирует закрытие соединения и возвращает клиенту 504

#### **Восстановление**

Убрать обработчик /slow и директиву proxy_read_timeout 3s

```
sudo nginx -t && sudo systemctl reload nginx
sudo systemctl restart support-app.service
```

#### **Проверка**

`curl -i -H 'Host: support.local' http://127.0.0.1/` =200
`curl -i -H 'Host: support.local' http://127.0.0.1/slow ` = 404

#### **Вывод**

- 504 означает, что соединение с backend есть, а ответа нет.
- 502 означает, что соединения или корректного ответа нет вообще.
