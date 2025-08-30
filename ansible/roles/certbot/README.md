# Certbot Role

This role installs and configures Certbot with Cloudflare DNS validation for automatic SSL certificate management from Let's Encrypt.

## Requirements

- Cloudflare DNS API token must be set in the environment variable `CLOUDFLARE_KIMDEVS`
- Target system must have internet access to reach Let's Encrypt servers

## Variables

### Required Variables

- `certbot_domains`: List of domains to obtain certificates for
  ```yaml
  certbot_domains:
    - example.com
    - '*.example.com'
  ```

### Optional Variables

- `certbot_mail`: Email address for Let's Encrypt registration (default: `server@kimdevs.ru`)
- `certbot_deploy_hook`: Command to run after certificate renewal (default: `systemctl reload nginx`)
- `certbot_dns_propagation_seconds`: DNS propagation timeout in seconds (default: `60`)

## Usage

Include this role in your playbook:

```yaml
- hosts: webservers
  roles:
    - role: certbot
      vars:
        certbot_domains:
          - example.com
          - '*.example.com'
        certbot_deploy_hook: "systemctl reload nginx"
```

## Features

- Installs Certbot and Cloudflare DNS plugin
- Creates secure configuration for Cloudflare API credentials
- Obtains SSL certificates using DNS-01 challenge
- Supports wildcard certificates
- Automatic certificate renewal (handled by Certbot's built-in timer)
- Configurable deploy hooks for service reloading

## Notes

Certbot includes a built-in timer service that automatically renews certificates before they expire. Each service using the certificates should implement its own deploy hooks for reloading after certificate renewal.
