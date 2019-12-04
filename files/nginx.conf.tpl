server {
    listen       80;
    server_name ${server_name};
    location / {
	proxy_pass   http://127.0.0.1:8080;
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}

