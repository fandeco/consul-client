build:
	docker build -t webnitros/consul-client:latest .
push:
	docker login
	docker buildx create --use
	docker buildx build --platform linux/arm64,linux/amd64 -t webnitros/consul-client:latest --push .
up:
	docker compose up -d
stop:
	docker compose stop
down:
	docker compose down --volumes --remove-orphans

destroy:
	docker compose down --volumes --remove-orphans
destroy-all:
	docker compose down --rmi all --volumes --remove-orphans
install:
	@make build
	@make up
remake:
	@make install
	@make up
