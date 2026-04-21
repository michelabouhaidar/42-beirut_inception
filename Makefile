NAME        = se-docker
LOGIN       := $(shell whoami)
DATA_DIR    = /home/$(LOGIN)/data
COMPOSE     = docker compose -f srcs/docker-compose.yml

.PHONY: all up down re build logs ps clean fclean

all: up

up:
	mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

re: down up

build:
	mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
	$(COMPOSE) build

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean: down
	docker system prune -af

fclean: down
	docker system prune -af
	docker volume prune -f
	rm -rf $(DATA_DIR)