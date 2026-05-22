NAME        := inception
LOGIN       := $(shell whoami)
DATA_DIR    := /home/$(LOGIN)/data
WP_DATA     := $(DATA_DIR)/wordpress
DB_DATA     := $(DATA_DIR)/mariadb
COMPOSE     := docker compose -f srcs/docker-compose.yml
SERVICES    := mariadb wordpress nginx


help:
	@printf "_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_ INCEPTION _-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_\n\n"
	@printf ">> make up         			Build images and start the stack (detached)\n"
	@printf ">> make down       			Stop and remove containers (keep volumes)\n"
	@printf ">> make stop       			Stop containers without removing them\n"
	@printf ">> make start      			Start previously stopped containers\n"
	@printf ">> make restart    			Restart all containers\n"
	@printf ">> make re         			down + up (preserves volumes)\n"
	@printf ">> make rebuild    			Rebuild images from scratch (no cache)\n"
	@printf ">> make build      			Build images only\n"
	@printf ">> make logs       			Follow logs from all containers\n"
	@printf ">> make logs-<svc> 			Follow logs from one service (mariadb|wordpress|nginx)\n"
	@printf ">> make sh-<svc>   			Open a shell inside one service\n"
	@printf ">> make ps         			List running containers\n"
	@printf ">> make status     			Detailed health snapshot\n"
	@printf ">> make clean      			Stop containers + prune unused docker resources\n"
	@printf ">> make fclean     			Full reset: containers, volumes, images, host data\n"

all: up

$(DATA_DIR) $(WP_DATA) $(DB_DATA):
	@mkdir -p $@

up: build | $(WP_DATA) $(DB_DATA)
	$(COMPOSE) up -d
	@printf ">> Stack is up. Visit https://$$(grep DOMAIN_NAME srcs/.env | cut -d= -f2)\n"

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

restart:
	$(COMPOSE) restart

re: down up

build: | $(WP_DATA) $(DB_DATA)
	@for svc in $(SERVICES); do \
		$(COMPOSE) build $$svc || exit 1; \
	done

rebuild: | $(WP_DATA) $(DB_DATA)
	@for svc in $(SERVICES); do \
		$(COMPOSE) build --no-cache $$svc || exit 1; \
	done


logs:
	$(COMPOSE) logs -f

logs-%:
	$(COMPOSE) logs -f $*

ps:
	$(COMPOSE) ps

status:
	@printf "── Containers ──\n"
	$(COMPOSE) ps
	@printf "\n── Volumes ──\n"
	docker volume ls --filter "name=srcs_" --format "table {{.Name}}\t{{.Driver}}"
	@printf "\n── Network ──\n"
	docker network ls --filter "name=srcs_" --format "table {{.Name}}\t{{.Driver}}"
	@printf "\n── Host data ──\n"
	du -sh $(DATA_DIR)/* 2>/dev/null || printf "  (no data yet)\n"

sh-%:
	$(COMPOSE) exec $* sh

clean: down
	docker system prune -af

fclean:
	$(COMPOSE) down -v --remove-orphans 2>/dev/null || true
	docker system prune -af
	docker volume prune -f
	@sudo rm -rf $(DATA_DIR)

prune: clean