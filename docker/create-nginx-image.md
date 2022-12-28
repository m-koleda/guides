#### Задача:
Собрать docker image, который включает в себя приложение и веб-сервер Nginx, при запуске открыть порт 80 и добавить контейнер в автостарт системы. 

#### Подготовка  

Должен быть установлен Docker.  

Создаем папку с проектом и переходим в неё:  

    mkdir nginx && cd nginx  

Создаем папку html и кладем в неё свое веб-приложение, в моем случае index.html:  

    mkdir html
    cp ~/index.html ~/nginx/html/

Создаем папку .nginx и в ней файл nginx.conf:

    mkdir .nginx
    nano nginx.conf
    
Со следующим содержимым:

    # Запускать в качестве менее привилегированного пользователя по соображениям безопасности..
    user nginx;

    # Значение auto устанавливает число максимально доступных ядер CPU,
    # чтобы обеспечить лучшую производительность.
    worker_processes    auto;

    events { worker_connections 1024; }

    http {
        server {
            # Hide nginx version information.
            server_tokens off;

            listen  80;
            root    /usr/share/nginx/html;
            include /etc/nginx/mime.types;

            location / {
                try_files $uri $uri/ /index.html;
                charset utf-8;
            }

            gzip            on;
            gzip_vary       on;
            gzip_http_version  1.0;
            gzip_comp_level 5;
            gzip_types
                            application/atom+xml
                            application/javascript
                            application/json
                            application/rss+xml
                            application/vnd.ms-fontobject
                            application/x-font-ttf
                            application/x-web-app-manifest+json
                            application/xhtml+xml
                            application/xml
                            font/opentype
                            image/svg+xml
                            image/x-icon
                            text/css
                            text/plain
                            text/x-component;
            gzip_proxied    no-cache no-store private expired auth;
            gzip_min_length 256;
            gunzip          on;
        }
    }
    
Чтобы получить Docker-образ, создаем следующий файл Dockerfile:

    FROM nginx:alpine
    
    # Заменяем дефолтную страницу nginx соответствующей веб-приложению
    RUN rm -rf /usr/share/nginx/html/*
    COPY ./html /usr/share/nginx/html
    # Заменяем файл nginx.conf на кастомный
    COPY ./.nginx/nginx.conf /etc/nginx/nginx.conf
    
    # Точка входа образа, гарантирует, что Nginx останется «на переднем плане»
    ENTRYPOINT ["nginx", "-g", "daemon off;"]
    # Открываем наружу порт 80
    EXPOSE 80

#### Создание и запуск образа

Создаем образ с именем nginx-webapp и тегом v1:  

    docker build -t nginx-webapp:v1 .

Запускаем образ с помощью команды docker run:

    docker run --name nginx-webapp -d --restart unless-stopped -p 1234:80 nginx-webapp:v1
    
Флаг --restart unless-stopped настраивает контейнер на постоянный перезапуск, пока контейнер не остановишь вручную.  
Флаг -d запускает контейнер в фоновом режиме, флаг -p 1234:80 пробрасывает порты: локалхост 1234 - 80 контейнер.

Если у вас уже есть запущенный контейнер, для которого вы хотите изменить политику перезапуска,  
вы можете использовать команду docker update, чтобы изменить это:

    docker update --restart unless-stopped container_id


![image](https://user-images.githubusercontent.com/97964258/209825591-1642ffda-a6b9-4bf2-a85b-e1e15d5a75a1.png)  

![image](https://user-images.githubusercontent.com/97964258/209825691-7ca2a590-52db-4992-9280-df39a9a2dffb.png)  

  
  
Использованные ресурсы:  
<https://nginx.org/en/docs/beginners_guide.html>  
<https://nginx.org/en/docs/example.html>  
<https://proglib.io/p/kak-zapustit-nginx-v-docker-2020-05-12>  
<https://docs.docker.com/config/containers/start-containers-automatically/>
