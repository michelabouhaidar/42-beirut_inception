NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml

.PHONY: all up down re build logs ps clean fclean

all: up

up:
	$(COMPOSE) up -d --build

build:
	$(COMPOSE) build

down:
	$(COMPOSE) down

re: down up

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean: down
	docker system prune -af

fclean: down
	docker system prune -af
	docker volume prune -f