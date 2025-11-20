```shell
docker compose -f docker-compose.dev.yml --env-file .env.dev up --build
```

Development
```shell
docker compose --env-file .env up --build -d
```

To test the prod version go to [app.test](http://app.test)

To make this work you will need to add the followinf domains to your hosts file
```
app.test
api.test
traefik.test
```
to do that on Linux/macOS you will need to edit
```shell
sudo nano /etc/hosts
```
Add
```
127.0.0.1   app.test
127.0.0.1   api.test
127.0.0.1   traefik.test
```
and on Windows
```shell
notepad C:\Windows\System32\drivers\etc\hosts
```
and add
```
127.0.0.1   app.test
127.0.0.1   api.test
127.0.0.1   traefik.test
```

You need to do this as browsers need a host header
```
GET / HTTP/1.1
Host: app.test
```
and Traefik mathces headers with your router links
```
traefik.http.routers.frontend.rule=Host(`app.test`)
```
Without the hosts file entry:
- The request will not include the correct Host name.
- Traefik will not match the router.
- Traefik returns 404 page not found.
