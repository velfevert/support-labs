### Порт 8080 занят

В одном терминале был запущен процесс `python3 -m http.server 8080 --bind 0.0.0.0`, которые слушает все локальные адреса машины на порту 8080

В другом терминале `sudo systemctl start support-app.service`

#### **Диагностика**

1. `systemctl status support-app.service` состояние сервиса: `active: failed`, последний процесс завершился с ненулевым кодом
2. `sudo journalctl -u support-app.service -n 20 --no-pager` в журнале событий сервиса можно увидеть примерно следующее:
```
python3[<pid>]: OSError: [Errno 98] Address already in use
systemd[1]: support-app.service: Main process exited, code=exited, status=1/FAILURE
systemd: ... Failed with result 'exit-code'
systemd: ... Scheduler restart job, restart counter is at 5.
systemd: ... Start reaquest repeated too quickly.
systemd: Failed to start support-app.service - Support training application
```
Приложение пишет, что адрес уже занят, сразу завершается, systemd слишком часто пытался запускать сервис за короткий промежуток времени.

3. `sudo ss -lntp 'sport = :8080` смотрим какой процесс занимает порт 8080
4. Что это за процесс `ps -o user,pid,ppid,tt,cmd`, видим команду, которой был запущен процесс, также у него есть tty и его родителем является текущая оболочка, то есть процесс запущен вручную, не через systemd

#### **Восстановление**

1. Выясняем, кому приндлежит порт, нужен ли этот процесс
2. `kill <pid>`, в крайнем случае `kill -9 <pid>`
3. `reset-failed` явно сбрасывает состояние `failed` и счётчики неудачных стартов. Через некоторое время лимит самостоятельно откатывается
```
sudo systemctl reset-failed support-app.service
sudo systemctl start support-app.service
```

#### **Проверка**

Состояние должно быть active (running), pid процессе на сокете совпадает с пидом главного процесса сервиса, `curl` возвращает 200 ok
```
systemctl status support-app.service
sudo ss -lntp 'sport = :8080'
curl -i http://127.0.0.1:8080/
```
