# Nginx Role

This role installs and configures Nginx web server with optimized performance settings, SSL/TLS support, and comprehensive configuration management.

## Requirements

- Ubuntu/Debian-based system
- Root or sudo privileges

## Variables

### Basic Configuration

- `nginx_configs_dir`: Nginx configuration directory (default: `/etc/nginx`)
- `nginx_service`: Nginx service name (default: `nginx`)

### Feature Toggles

- `nginx_generate_dhparams`: Generate DH parameters for SSL (default: `true`)
- `nginx_configure_default_site`: Configure default site (default: `true`)
- `nginx_configure_logrotate`: Configure log rotation (default: `true`)
- `nginx_configure_kernel_params`: Configure kernel parameters (default: `true`)
- `nginx_load_conntrack`: Load conntrack kernel module (default: `true`)
- `nginx_reconfigure`: Force reconfiguration (default: `false`)

### Performance Settings

- `nginx_worker_processes`: Number of worker processes (default: auto-detected CPU count)
- `nginx_worker_connections`: Worker connections per process (default: `2048`)
- `nginx_worker_rlimit_nofile`: File descriptor limit (default: `16384`)
- `nginx_keepalive_timeout`: Keepalive timeout in seconds (default: `65`)
- `nginx_client_max_body_size`: Maximum client body size (default: `100M`)

### SSL/TLS Settings

- `nginx_ssl_protocols`: SSL protocols (default: `TLSv1.2 TLSv1.3`)
- `nginx_ssl_ciphers`: SSL ciphers (default: `ECDHE-RSA-AES128-GSS-SHA256:ECDHE-RSA-AES256-GSS-SHA256`)

### Kernel Tuning

- `nginx_somaxconn`: Maximum socket connections (default: `150000`)
- `nginx_nf_conntrack_max`: Netfilter conntrack maximum (default: `1548576`)

## Configuration Structures

### Sites Configuration

```yaml
nginx_sites:
  mysite:
    - listen 80
    - server_name example.com
    - location /:
        - proxy_pass http://backend
        - proxy_set_header Host $host
    - location /.well-known/acme-challenge:
        - root /var/www/certbot
  api:
    - listen 443 ssl http2
    - server_name api.example.com
    - ssl_certificate /etc/letsencrypt/live/api.example.com/fullchain.pem
    - ssl_certificate_key /etc/letsencrypt/live/api.example.com/privkey.pem
    - location /:
        - proxy_pass http://api_backend
```

### Upstream Configuration

```yaml
nginx_upstreams:
  backend:
    - server backend1.example.com:8080 weight=3
    - server backend2.example.com:8080 weight=1
    - server backend3.example.com:8080 backup
  api_backend:
    - server api1.example.com:3000
    - server api2.example.com:3000
```

### Stream Configuration

```yaml
nginx_streams:
  mysql_proxy:
    - listen 3306
    - proxy_pass backend_mysql
  redis_proxy:
    - listen 6379
    - proxy_pass backend_redis
```

## Usage

### Basic Installation

```yaml
- hosts: webservers
  roles:
    - role: nginx
```

### Configure Reverse Proxy

```yaml
- hosts: webservers
  roles:
    - role: nginx
      vars:
        nginx_sites:
          app:
            - listen 80
            - server_name myapp.com
            - location /:
                - proxy_pass http://localhost:3000
                - proxy_set_header Host $host
                - proxy_set_header X-Real-IP $remote_addr
```

### Configure Load Balancer

```yaml
- hosts: loadbalancers
  roles:
    - role: nginx
      vars:
        nginx_upstreams:
          webapp:
            - server web1.example.com:80 weight=2
            - server web2.example.com:80 weight=1
            - server web3.example.com:80 backup
        nginx_sites:
          app:
            - listen 80
            - server_name app.example.com
            - location /:
                - proxy_pass http://webapp
                - proxy_set_header Host $host
```

### Configure SSL/TLS

```yaml
- hosts: webservers
  roles:
    - role: nginx
      vars:
        nginx_sites:
          secure_app:
            - listen 443 ssl http2
            - server_name secure.example.com
            - ssl_certificate /etc/letsencrypt/live/secure.example.com/fullchain.pem
            - ssl_certificate_key /etc/letsencrypt/live/secure.example.com/privkey.pem
            - ssl_protocols TLSv1.2 TLSv1.3
            - ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384
            - location /:
                - proxy_pass http://backend
```

## Features

- **Performance Optimized**: Auto-tuned worker processes and connections
- **SSL/TLS Support**: Full HTTPS configuration with DH parameters
- **Load Balancing**: Upstream configuration with weights and backup servers
- **Stream Support**: TCP/UDP proxy support for databases and services
- **Security**: Proper file permissions and secure defaults
- **Monitoring**: Built-in status page for monitoring
- **Log Management**: Automatic log rotation configuration
- **Kernel Tuning**: Optimized kernel parameters for high traffic

## Tags

- `nginx`: All tasks
- `install`: Package installation
- `configure`: Configuration tasks
- `sites`: Site configuration
- `upstreams`: Upstream configuration
- `streams`: Stream configuration
- `ssl`: SSL/TLS related tasks
- `logrotate`: Log rotation configuration
- `kernel`: Kernel parameter tuning

## Examples

### Complete Web Application Setup

```yaml
- hosts: webservers
  roles:
    - role: nginx
      vars:
        nginx_worker_processes: 4
        nginx_worker_connections: 4096
        nginx_upstreams:
          app_servers:
            - server app1:8080 weight=2
            - server app2:8080 weight=2
            - server app3:8080 backup
        nginx_sites:
          main:
            - listen 80
            - server_name myapp.com www.myapp.com
            - location /:
                - proxy_pass http://app_servers
                - proxy_set_header Host $host
                - proxy_set_header X-Real-IP $remote_addr
                - proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for
                - proxy_set_header X-Forwarded-Proto $scheme
          api:
            - listen 443 ssl http2
            - server_name api.myapp.com
            - ssl_certificate /etc/letsencrypt/live/api.myapp.com/fullchain.pem
            - ssl_certificate_key /etc/letsencrypt/live/api.myapp.com/privkey.pem
            - location /:
                - proxy_pass http://api_servers
```

## Notes

- The role automatically generates DH parameters for SSL if enabled
- Configuration files are validated using `nginx -t` before applying
- The role supports both HTTP and stream (TCP/UDP) proxying
- Kernel parameters are tuned for high-traffic scenarios
- Log rotation is configured to run every 5 minutes
