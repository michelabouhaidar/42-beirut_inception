*This project has been created as part of the 42 curriculum by mabou-ha.*

# Inception

## Description

Inception is a system administration project that sets up a small web infrastructure using Docker Compose inside a virtual machine. The stack consists of three services — NGINX, WordPress with php-fpm, and MariaDB — each running in its own container, connected through a dedicated Docker bridge network. NGINX serves as the single entry point on port 443 with TLS, forwarding PHP requests to WordPress via FastCGI, which in turn queries MariaDB for persistent data storage.

All Docker images are built from custom Dockerfiles based on Debian Bookworm. No pre-built application images are pulled from DockerHub. Sensitive credentials are managed through Docker secrets, and environment-specific variables are stored in a `.env` file that is excluded from version control.

### Project Description — Design Choices

This project uses Docker containers rather than full virtual machines to isolate each service. The infrastructure is orchestrated by Docker Compose, with a Makefile providing convenient build, start, stop, and cleanup targets.

Key design decisions include:

- **Debian Bookworm** as the base image for all three services, chosen for its broad package availability and long-term support.
- **Self-signed TLS certificates** generated at build time inside the NGINX container, avoiding the need to commit private keys to the repository.
- **Docker secrets** for all passwords (database root, database user, WordPress admin, WordPress editor), read from files at container runtime.
- **Named volumes with local driver** for WordPress files and MariaDB data, stored on the host at `/home/<login>/data/`.

### Virtual Machines vs Docker

Virtual machines emulate an entire operating system with its own kernel, providing strong isolation but consuming significant resources (RAM, disk, boot time). Docker containers share the host kernel and run as isolated processes, making them far more lightweight. A VM might take minutes to boot; a container starts in seconds. For this project, Docker is the right fit because each service only needs its own user-space environment, not a full OS.

### Secrets vs Environment Variables

Environment variables are visible in `docker inspect`, process listings, and child processes — they are not designed for sensitive data. Docker secrets mount credential files into `/run/secrets/` inside the container with restricted permissions, making them accessible only to the processes that need them. In this project, all passwords use secrets; non-sensitive configuration (domain name, database name, usernames) uses environment variables.

### Docker Network vs Host Network

Host networking removes network isolation between the container and the host, meaning every container port is directly exposed. A Docker bridge network creates an isolated subnet where containers communicate by service name, and only explicitly published ports reach the host. This project uses a bridge network so that only NGINX's port 443 is exposed externally, while MariaDB (3306) and php-fpm (9000) remain internal.

### Docker Volumes vs Bind Mounts

Bind mounts map an arbitrary host path into a container, tightly coupling the container to the host's filesystem layout. Docker named volumes are managed by Docker and offer better portability, backup tooling, and permission handling. This project uses named volumes with `driver_opts` to store data at a specific host path (`/home/<login>/data/`) as required by the subject, combining the management benefits of named volumes with a known host location.

## Instructions

### Prerequisites

- A Linux virtual machine (Debian/Ubuntu recommended)
- Docker Engine and Docker Compose (v2) installed
- `make` installed
- Entry in `/etc/hosts` mapping `mabou-ha.42.fr` to `127.0.0.1`

### Setup

1. Clone the repository.
2. Create `srcs/.env` based on `srcs/.env.example` and fill in your values.
3. Create the `secrets/` directory at the project root with the following files, each containing a single password on one line:
   - `secrets/db_root_password.txt`
   - `secrets/db_password.txt`
   - `secrets/wp_admin_password.txt`
   - `secrets/wp_user_password.txt`
4. Add your domain to `/etc/hosts`:
   ```
   127.0.0.1  mabou-ha.42.fr
   ```
5. Run:
   ```
   make
   ```
6. Visit `https://mabou-ha.42.fr` in your browser (accept the self-signed certificate warning).

### Makefile Targets

`make` alone prints the help menu. Use `make up` to start the stack.

| Target             | Description                                              |
|--------------------|----------------------------------------------------------|
| `make up`          | Build images and start the stack (detached)              |
| `make down`        | Stop and remove containers (volumes preserved)           |
| `make stop`        | Stop containers without removing them                    |
| `make start`       | Start previously stopped containers                      |
| `make restart`     | Restart all containers                                   |
| `make re`          | down + up (preserves volumes)                            |
| `make build`       | Build images only (no start)                             |
| `make rebuild`     | Rebuild images from scratch (no cache)                   |
| `make logs`        | Follow logs from all containers                          |
| `make logs-<svc>`  | Follow logs from one service (`mariadb`\|`wordpress`\|`nginx`) |
| `make sh-<svc>`    | Open a shell inside a service container                  |
| `make ps`          | List running containers                                  |
| `make status`      | Detailed snapshot: containers, volumes, network, host data |
| `make clean`       | Stop containers and prune unused Docker resources        |
| `make fclean`      | Full reset: containers, volumes, images, host data       |

## Resources

### References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) (Compose adaptation)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress CLI (wp-cli)](https://wp-cli.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [Debian Docker Hub](https://hub.docker.com/_/debian)
- [PID 1 and Docker best practices](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)

### AI Usage

AI (Claude by Anthropic) was used during this project for the following tasks:

- **Reviewing and auditing** the project structure against the subject requirements, identifying missing files and compliance issues.
- **Generating documentation** (this README, USER_DOC.md, DEV_DOC.md) based on the actual project code and the subject specification.
- **Restructuring** the directory layout to match the expected `conf/` and `tools/` subdirectory convention.
- **Improving security practices**: moving from committed SSL certificates to build-time generation, and ensuring secrets are excluded from version control.

All generated content was reviewed, understood, and adapted by the project author before inclusion.
