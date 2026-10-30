### Self-signed TLS-сертификат для static.local

#### Когда использовать

Нужно создать сертификат и ключ для `static.local` или проверить, что установленный сертификат корректен. Сертификат и ключ в репозиторий не коммитятся (`.gitignore`).

#### Создание

Создаем защищенный каталога для хранения приватного ключа
`sudo install -d -m 700 -o root -g root /etc/nginx/ssl`

Для генерации серта используется команда `openssl req`

```
sudo openssl req -new -x509 \
-key /etc/nginx/ssl/static.local.key \
-out /etc/nginx/ssl/static.local-new.crt \
-days 365 -subj "/CN=static.local" \
-addext "subjectAltName=DNS:static.local" \
-addext "basicConstraints=critical,CA:FALSE" \
-addext "keyUsage=critical,digitalSignature,keyEncipherment" \
-addext "extendedKeyUsage=serverAuth"
```

Права на файл с приватным ключом должны быть 600, при генерации ключей openssl может уже установить ограничительные права на этот файл.

Чтобы хост использовал https надо три дериктивы:

- `listen 443 ssl;`
- `ssl_certificate /etc/nginx/ssl/static.local-new.crt;`
- `ssl_certificate_key /etc/nginx/ssl/static.local.ke;`

#### Проверка

Посмотреть сертификат
```
sudo openssl x509 \
-in /etc/nginx/ssl/static.local-new.crt \
-noout -text
```

`nginx -t` также проверит возможность загрузки серта и приватного ключа, если они не соответствуют, openssl/nginx должен обнаружить проблему.

Проверка https через curl

`curl -i --resolve static.local:443:127.0.0.1 --cacert /etc/nginx/ssl/static.local-new.crt https://static.local/`

`curl --cacert` позволяет выполнить проверку с указанным доверенным сертом, не добавляя его в хранилище

`curl -k` отключает проверку подлинности сертификата
