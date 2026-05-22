# Developer Documentation — Inception

## Setting Up the Environment from Scratch

### Prerequisites

- A virtual machine running Debian or Ubuntu (required by the subject)
- Docker Engine (v20.10+) and Docker Compose v2 installed
- `make` and `git` installed
- Root or sudo access (Docker typically requires it)

### Configuration Files

1. **`srcs/.env`** — Copy from `srcs/.env.example` and customize:
   ```
   cp srcs/.env.example srcs/.env
   ```
   Edit `DOMAIN_NAME`, `MYSQL_USER`, `WP_ADMIN_USER`, etc. The admin username must not contain "admin" or "administrator" in any case variation.

2. **`secrets/`** — Create the directory and populate four password files:
   ```
   mkdir -p secrets
   echo "your_db_root_pw"    > secrets/db_root_password.txt
   echo "your_db_user_pw"    > secrets/db_password.txt
   echo "your_wp_admin_pw"   > secrets/wp_admin_password.txt
   echo "your_wp_editor_pw"  > secrets/wp_user_password.txt
   ```
   These files are referenced by Docker Compose as secrets and mounted at `/run/secrets/` inside the relevant containers.

3. **`/etc/hosts`** — Add a DNS entry for your domain:
   ```
   sudo sh -c 'echo "127.0.0.1  mabou-ha.42.fr" >> /etc/hosts'
   ```

## Building and Launching

The Makefile orchestrates everything:

```
make             # Print the help menu (default target)
make up          # Build images and start the stack (detached)
make down        # Stop and remove containers (volumes preserved)
make stop        # Stop containers without removing them
make start       # Start previously stopped containers
make restart     # Restart all containers
make re          # down + up (preserves volumes)
make build       # Build images only (no start)
make rebuild     # Rebuild images from scratch (no cache)
make logs        # Tail logs from all containers
make logs-<svc>  # Tail logs from one service (mariadb|wordpress|nginx)
make sh-<svc>    # Open a shell inside a service container
make ps          # List running containers
make status      # Snapshot: containers, volumes, network, host data sizes
make clean       # Stop containers + prune unused Docker resources
make fclean      # Full reset: containers, volumes, images, host data
```

Under the hood, `make` runs `docker compose -f srcs/docker-compose.yml up -d --build`, which reads the Compose file, builds each image from its Dockerfile, and starts the containers.

## Container Management

### Entering a container

```
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash
```

### Checking MariaDB

```
docker exec -it mariadb mysql -uroot -p"$(cat secrets/db_root_password.txt)" -e "SHOW DATABASES;"
docker exec -it mariadb mysql -uroot -p"$(cat secrets/db_root_password.txt)" wordpress -e "SELECT user_login FROM wp_users;"
```

### Running WP-CLI commands

```
docker exec -it wordpress wp user list --allow-root
docker exec -it wordpress wp option get siteurl --allow-root
```

### Inspecting the network

```
docker network ls
docker network inspect srcs_network_bridged
```

### Viewing volumes

```
docker volume ls
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_mariadb_data
```

## Project Data: Storage and Persistence

### Named Volumes

Two Docker named volumes persist data across container restarts and rebuilds:

| Volume                  | Container mount      | Host path                         | Content                     |
|-------------------------|----------------------|-----------------------------------|-----------------------------|
| `srcs_wordpress_data`   | `/var/www/html`      | `/home/mabou-ha/data/wordpress`   | WordPress core files, themes, plugins, uploads |
| `srcs_mariadb_data`     | `/var/lib/mysql`     | `/home/mabou-ha/data/mariadb`     | MariaDB database files      |

The volumes use the `local` driver with `driver_opts` to store data at a specific host path. This is functionally similar to a bind mount but managed as a named volume by Docker.

### What happens on `make fclean`

The `fclean` target stops containers, prunes all Docker resources (images, containers, networks), removes all Docker volumes, and deletes the `/home/<login>/data/` directory. This is a full reset — all WordPress content and database records are permanently destroyed.

### First-run initialization

On the very first `make`, the entrypoint scripts perform one-time setup:

- **MariaDB**: `mysql_install_db` initializes the data directory, then a temporary mysqld instance runs SQL to create the database, users, and set the root password.
- **WordPress**: WP-CLI downloads WordPress core into the volume, generates `wp-config.php`, installs the site, and creates the admin and editor users.

On subsequent starts, both entrypoints detect existing data and skip initialization.

## Directory Structure

```
.
├── Makefile                        # Build/run orchestration
├── README.md                       # Project overview and comparisons
├── USER_DOC.md                     # End-user documentation
├── DEV_DOC.md                      # This file
├── .gitignore                      # Excludes secrets/, .env, certs
├── secrets/                        # Password files (NOT in git)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                        # Environment variables (NOT in git)
    ├── .env.example                # Template for .env
    ├── docker-compose.yml          # Service definitions
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── 50-server.cnf   # MariaDB server config
        │   └── tools/
        │       └── entrypoint.sh   # Init + startup script
        ├── nginx/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── default         # NGINX site config (TLS + fastcgi)
        │   └── tools/              # (empty — no runtime scripts needed)
        └── wordpress/
            ├── Dockerfile
            ├── .dockerignore
            ├── conf/
            │   └── www.conf        # php-fpm pool configuration
            └── tools/
                └── script.sh        # WP setup + startup script
```
