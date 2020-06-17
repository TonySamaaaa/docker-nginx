# docker-nginx

### How to run

	docker run -d --restart always \
	  -p 80:80 -p 443:443 \
	  -v /etc/localtime:/etc/localtime:ro \
	  -v /data/docker/nginx/conf.d:/etc/nginx/conf.d:ro \
	  -v /data/docker/nginx/certs.d:/etc/nginx/certs.d:ro \
	  -v /data/wwwroot:/data/wwwroot \
	  -v /data/wwwlogs:/data/wwwlogs \
	  --name nginx tonysamaaaa/nginx

#### or

	curl -L "https://raw.githubusercontent.com/TonySamaaaa/docker-nginx/master/nginx/nginx.conf" \
	  -o /data/docker/nginx/nginx.conf
	docker run -d --restart always \
	  -v /etc/localtime:/etc/localtime:ro \
	  -v /data/docker/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
	  -v /data/docker/nginx/conf.d:/etc/nginx/conf.d:ro \
	  -v /data/docker/nginx/certs.d:/etc/nginx/certs.d:ro \
	  -v /data/wwwroot:/data/wwwroot \
	  -v /data/wwwlogs:/data/wwwlogs \
	  --network host --name nginx tonysamaaaa/nginx

### Adding a vhost

	curl -L "https://raw.githubusercontent.com/TonySamaaaa/docker-nginx/master/example/example.com.conf" \
	  -o /data/docker/nginx/conf.d/example.com.conf
	vi /data/docker/nginx/conf.d/example.com.conf