# ============================================================================
#  Inception — Docker Compose orchestration
# ============================================================================

NAME        := inception
LOGIN       := $(shell whoami)
DATA_DIR    := /home/$(LOGIN)/data
WP_DATA     := $(DATA_DIR)/wordpress
DB_DATA     := $(DATA_DIR)/mariadb
COMPOSE     := docker compose -f srcs/docker-compose.yml
SERVICES    := mariadb wordpress nginx

# Pretty output
GREEN       := \033[0;32m
YELLOW      := \033[0;33m
CYAN        := \033[0;36m
RED         := \033[0;31m
NC          := \033[0m

.DEFAULT_GOAL := help
.PHONY: help all up down stop start restart re build rebuild \
        logs ps status clean fclean prune \
        $(addprefix logs-,$(SERVICES)) $(addprefix sh-,$(SERVICES))

# ----------------------------------------------------------------------------
#  Help
# ----------------------------------------------------------------------------
help:
	@printf "$(CYAN)Inception — available targets$(NC)\n"
	@printf "  $(GREEN)make up$(NC)         Build images and start the stack (detached)\n"
	@printf "  $(GREEN)make down$(NC)       Stop and remove containers (keep volumes)\n"
	@printf "  $(GREEN)make stop$(NC)       Stop containers without removing them\n"
	@printf "  $(GREEN)make start$(NC)      Start previously stopped containers\n"
	@printf "  $(GREEN)make restart$(NC)    Restart all containers\n"
	@printf "  $(GREEN)make re$(NC)         down + up (preserves volumes)\n"
	@printf "  $(GREEN)make rebuild$(NC)    Rebuild images from scratch (no cache)\n"
	@printf "  $(GREEN)make build$(NC)      Build images only\n"
	@printf "  $(GREEN)make logs$(NC)       Follow logs from all containers\n"
	@printf "  $(GREEN)make logs-<svc>$(NC) Follow logs from one service (mariadb|wordpress|nginx)\n"
	@printf "  $(GREEN)make sh-<svc>$(NC)   Open a shell inside one service\n"
	@printf "  $(GREEN)make ps$(NC)         List running containers\n"
	@printf "  $(GREEN)make status$(NC)     Detailed health snapshot\n"
	@printf "  $(YELLOW)make clean$(NC)      Stop containers + prune unused docker resources\n"
	@printf "  $(RED)make fclean$(NC)     Full reset: containers, volumes, images, host data\n"

# ----------------------------------------------------------------------------
#  Lifecycle
# ----------------------------------------------------------------------------
all: up

$(DATA_DIR) $(WP_DATA) $(DB_DATA):
	@mkdir -p $@

up: build | $(WP_DATA) $(DB_DATA)
	@printf "$(CYAN)>> Starting stack...$(NC)\n"
	@$(COMPOSE) up -d
	@printf "$(GREEN)>> Stack is up. Visit https://$$(grep DOMAIN_NAME srcs/.env | cut -d= -f2)$(NC)\n"

down:
	@printf "$(YELLOW)>> Stopping stack...$(NC)\n"
	@$(COMPOSE) down

stop:
	@$(COMPOSE) stop

start:
	@$(COMPOSE) start

restart:
	@$(COMPOSE) restart

re: down up

# ----------------------------------------------------------------------------
#  Build
# ----------------------------------------------------------------------------
build: | $(WP_DATA) $(DB_DATA)
	@printf "$(CYAN)>> Building images (one by one)...$(NC)\n"
	@for svc in $(SERVICES); do \
		printf "$(CYAN)   - $$svc$(NC)\n"; \
		$(COMPOSE) build $$svc || exit 1; \
	done

rebuild: | $(WP_DATA) $(DB_DATA)
	@printf "$(CYAN)>> Rebuilding images from scratch...$(NC)\n"
	@for svc in $(SERVICES); do \
		printf "$(CYAN)   - $$svc (no-cache)$(NC)\n"; \
		$(COMPOSE) build --no-cache $$svc || exit 1; \
	done

# ----------------------------------------------------------------------------
#  Observability
# ----------------------------------------------------------------------------
logs:
	@$(COMPOSE) logs -f

logs-%:
	@$(COMPOSE) logs -f $*

ps:
	@$(COMPOSE) ps

status:
	@printf "$(CYAN)── Containers ──$(NC)\n"
	@$(COMPOSE) ps
	@printf "\n$(CYAN)── Volumes ──$(NC)\n"
	@docker volume ls --filter "name=srcs_" --format "table {{.Name}}\t{{.Driver}}"
	@printf "\n$(CYAN)── Network ──$(NC)\n"
	@docker network ls --filter "name=srcs_" --format "table {{.Name}}\t{{.Driver}}"
	@printf "\n$(CYAN)── Host data ──$(NC)\n"
	@du -sh $(DATA_DIR)/* 2>/dev/null || printf "  (no data yet)\n"

sh-%:
	@$(COMPOSE) exec $* sh

# ----------------------------------------------------------------------------
#  Cleanup
# ----------------------------------------------------------------------------
clean: down
	@printf "$(YELLOW)>> Pruning unused docker resources...$(NC)\n"
	@docker system prune -af

fclean:
	@printf "$(RED)>> Full cleanup (containers, volumes, images, host data)...$(NC)\n"
	@$(COMPOSE) down -v --remove-orphans 2>/dev/null || true
	@docker system prune -af
	@docker volume prune -f
	@sudo rm -rf $(DATA_DIR)
	@printf "$(GREEN)>> Done.$(NC)\n"

prune: clean