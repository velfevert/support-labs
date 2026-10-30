
`sudo systemctl daemon-reload` говорит systemd перечитать unit-файлы с диска (/etc/systemd/system и /usr/lib/systemd) и обновить свою внутреннюю конфигурацию. Выполняется после создания или изменения unit-файла.

`sudo systemctl reload nginx` заставляет запущенный сервис перечитать свой конфиг; не все сервисы позволяют выполнить релоад

`sudo systemctl restart support-app.service` стоп - старт сервиса

`sudo systemctl status support-app.service` состояние сервиса

`sudo journalctl -u support-app.service -n 50` 50 последних событий сервиса

`sudo nginx -t` запускает отдельную проверку синтаксиса и возможность загрузки всех дополнительных конфигов

