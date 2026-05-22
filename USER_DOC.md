# User Documentation — Inception

## What This Stack Provides

Inception runs a complete WordPress website composed of three services, each in its own Docker container:

| Service | Role |
|---------|------|
| **NGINX** | The only entry point into the stack. Handles HTTPS on port 443, terminates TLS, and forwards PHP requests to WordPress via FastCGI. |
| **WordPress + php-fpm** | The content management system. Processes PHP pages and reads/writes data from MariaDB. |
| **MariaDB** | The relational database. Stores all WordPress content, users, settings, and media metadata. |

Containers communicate over an isolated Docker network. Only port **443 (HTTPS)** is reachable from outside.

---

## Prerequisites

Before starting, make sure the following are in place:

- Docker Engine and Docker Compose v2 are installed on the VM
- The `secrets/` directory exists at the project root with all four password files (see [Credentials](#credentials))
- `srcs/.env` is filled in (copy from `srcs/.env.example`)
- Your domain is in `/etc/hosts`:
  ```
  127.0.0.1  mabou-ha.42.fr
  ```

---

## Starting the Stack

```bash
make up
```

This builds the Docker images (first run only) and starts all three containers in the background. The first run takes a few minutes while Alpine packages are downloaded and WordPress is initialized.

> `make` alone prints the full list of available commands.

---

## Stopping the Stack

Stop and remove containers (data is preserved):

```bash
make down
```

Stop containers without removing them (faster resume):

```bash
make stop
```

Resume stopped containers:

```bash
make start
```

Restart all containers:

```bash
make restart
```

Full stop + rebuild + start (preserves volumes and data):

```bash
make re
```

---

## Accessing the Website

Open your browser and go to:

```
https://mabou-ha.42.fr
```

Your browser will warn about a self-signed certificate — this is expected. Click **Advanced** then **Accept the Risk and Continue** (Firefox) or **Proceed** (Chrome) to access the site.

> HTTP (`http://mabou-ha.42.fr`) is not served — NGINX only listens on port 443.

---

## Accessing the WordPress Admin Panel

```
https://mabou-ha.42.fr/wp-admin
```

Log in with the administrator credentials (username from `WP_ADMIN_USER` in `srcs/.env`, password from `secrets/wp_admin_password.txt`).

From the dashboard you can manage posts, pages, users, themes, and plugins.

---

## Credentials

### Password files

All passwords are stored as plain-text files in the `secrets/` directory at the project root:

| File | Used for |
|------|----------|
| `secrets/db_root_password.txt` | MariaDB root account |
| `secrets/db_password.txt` | MariaDB WordPress user (`MYSQL_USER`) |
| `secrets/wp_admin_password.txt` | WordPress administrator login |
| `secrets/wp_user_password.txt` | WordPress editor login |

### Usernames and other config

Non-sensitive settings live in `srcs/.env`:

| Variable | Purpose |
|----------|---------|
| `DOMAIN_NAME` | Site domain (e.g. `mabou-ha.42.fr`) |
| `MYSQL_DATABASE` | Database name |
| `MYSQL_USER` | Database username for WordPress |
| `WP_ADMIN_USER` | WordPress admin username |
| `WP_ADMIN_EMAIL` | WordPress admin email |
| `WP_USER` | WordPress editor username |
| `WP_USER_EMAIL` | WordPress editor email |

> The `secrets/` directory and `srcs/.env` are excluded from git. Never commit them.

---

## Checking That Services Are Running

Quick container status:

```bash
make ps
```

You should see `nginx`, `wordpress`, and `mariadb` all in a **running** state.

Full health snapshot (containers + volumes + network + host data sizes):

```bash
make status
```

Live logs from all services:

```bash
make logs
```

Logs from a single service only:

```bash
make logs-nginx
make logs-wordpress
make logs-mariadb
```

Press `Ctrl+C` to stop following logs.

Verify the site is responding from the command line:

```bash
curl -k https://mabou-ha.42.fr
```

A successful response returns WordPress HTML. The `-k` flag skips certificate verification (expected for self-signed certs).
