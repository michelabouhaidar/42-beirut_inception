# User Documentation — Inception

## What This Stack Provides

Inception runs a complete WordPress website composed of three services:

- **NGINX** — A reverse proxy and web server that handles HTTPS connections on port 443. It terminates TLS and forwards PHP requests to WordPress.
- **WordPress + php-fpm** — The content management system that serves your website. It processes PHP pages and communicates with MariaDB for data storage.
- **MariaDB** — The relational database that stores all WordPress content, users, settings, and metadata.

All three services run inside Docker containers, connected through an isolated network. Only port 443 (HTTPS) is exposed to the outside.

## Starting the Project

From the project root directory, run:

```
make up
```

This builds all container images (if not already built) and starts the stack in the background. The first run takes a few minutes while Docker downloads the base Debian image and installs packages.

> Running `make` alone prints the available commands help menu.

## Stopping the Project

```
make down
```

This stops all containers and removes them. Your data is preserved in the volumes at `/home/<login>/data/`.

To completely restart from scratch (stop, rebuild, start):

```
make re
```

## Accessing the Website

Open your browser and navigate to:

```
https://mabou-ha.42.fr
```

Your browser will show a certificate warning because the TLS certificate is self-signed. This is expected — accept the warning to proceed.

## Accessing the Administration Panel

The WordPress admin dashboard is available at:

```
https://mabou-ha.42.fr/wp-admin
```

Log in with the WordPress administrator credentials (see below).

## Credentials

Passwords are stored in the `secrets/` directory at the project root. Each file contains a single password:

| File                           | Purpose                        |
|--------------------------------|--------------------------------|
| `secrets/db_root_password.txt` | MariaDB root password          |
| `secrets/db_password.txt`      | MariaDB WordPress user password|
| `secrets/wp_admin_password.txt`| WordPress admin password       |
| `secrets/wp_user_password.txt` | WordPress editor password      |

The WordPress admin username and editor username are defined in `srcs/.env` (fields `WP_ADMIN_USER` and `WP_USER`).

To change a password, edit the corresponding file in `secrets/`, then restart the stack with `make re`. Note that database passwords require manual updates inside MariaDB if the database has already been initialized.

## Checking That Services Are Running

Run:

```
make ps
```

You should see three containers listed (`nginx`, `wordpress`, `mariadb`) all in a `running` state.

To view live logs from all services:

```
make logs
```

Press `Ctrl+C` to stop following logs.

You can also verify the website is responding:

```
curl -k https://mabou-ha.42.fr
```

A successful response returns the WordPress HTML page. The `-k` flag tells curl to accept the self-signed certificate.
