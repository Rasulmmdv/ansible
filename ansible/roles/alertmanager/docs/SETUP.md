# Alertmanager Setup Guide

This guide explains how to configure email and Telegram notifications for Alertmanager.

## Email Configuration

### Gmail Setup (Recommended)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate an App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a new app password for "Mail"
3. **Configure variables in your playbook**:

```yaml
alertmanager_email_smtp: "smtp.gmail.com:587"
alertmanager_email_from: "alertmanager@yourdomain.com"
alertmanager_email_to: "admin@yourdomain.com"
alertmanager_email_auth_username: "your-email@gmail.com"
alertmanager_email_auth_password: "your-16-character-app-password"
```

### Other SMTP Providers

For other providers, adjust the SMTP settings:

```yaml
# Outlook/Hotmail
alertmanager_email_smtp: "smtp-mail.outlook.com:587"

# Yahoo
alertmanager_email_smtp: "smtp.mail.yahoo.com:587"

# Custom SMTP Server
alertmanager_email_smtp: "your-smtp-server.com:587"
```

## Telegram Configuration

### Creating a Telegram Bot

1. **Start a chat with @BotFather** on Telegram
2. **Send `/newbot`** command
3. **Choose a name** for your bot
4. **Choose a username** (must end with 'bot')
5. **Save the bot token** provided by BotFather

### Getting Chat ID

#### Method 1: Using @userinfobot
1. Start a chat with @userinfobot
2. Send any message
3. The bot will reply with your chat ID

#### Method 2: Using Bot API
1. Send a message to your bot
2. Visit: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
3. Find your chat ID in the response

#### Method 3: Using curl
```bash
curl "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates"
```

### Configure Variables

```yaml
alertmanager_telegram_bot_token: "123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
alertmanager_telegram_chat_id: "123456789"
```

## Complete Playbook Example

```yaml
---
- name: Deploy Monitoring Stack with Alertmanager
  hosts: monitoring_servers
  become: true
  
  vars:
    # Email configuration
    alertmanager_email_smtp: "smtp.gmail.com:587"
    alertmanager_email_from: "alertmanager@yourdomain.com"
    alertmanager_email_to: "admin@yourdomain.com"
    alertmanager_email_auth_username: "your-email@gmail.com"
    alertmanager_email_auth_password: "your-app-password"
    
    # Telegram configuration
    alertmanager_telegram_bot_token: "123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
    alertmanager_telegram_chat_id: "123456789"
    
    # Alert routing
    alertmanager_route_group_wait: "30s"
    alertmanager_route_group_interval: "5m"
    alertmanager_route_repeat_interval: "4h"
  
  roles:
    - common
    - prometheus
    - alertmanager
```

## Testing Notifications

### Test Email
1. Create a test alert rule
2. Trigger the alert condition
3. Check your email inbox

### Test Telegram
1. Send a message to your bot: `/start`
2. Create a test alert rule
3. Trigger the alert condition
4. Check Telegram for notifications

### Manual Test via API
```bash
# Test email
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[
    {
      "labels": {
        "alertname": "TestAlert",
        "severity": "warning"
      },
      "annotations": {
        "summary": "Test alert",
        "description": "This is a test alert"
      }
    }
  ]'
```

## Troubleshooting

### Email Issues
- **Authentication failed**: Check username/password
- **Connection refused**: Check firewall and SMTP settings
- **TLS issues**: Verify `smtp_require_tls: true` in config

### Telegram Issues
- **Bot not responding**: Check bot token and chat ID
- **No notifications**: Ensure bot is started with `/start`
- **API errors**: Verify bot token format

### General Issues
- **Alertmanager not starting**: Check configuration syntax
- **Prometheus not connecting**: Verify network connectivity
- **Alerts not firing**: Check alert rule syntax and metrics

## Security Considerations

1. **Use environment variables** for sensitive data:
```yaml
alertmanager_email_auth_password: "{{ lookup('env', 'EMAIL_PASSWORD') }}"
alertmanager_telegram_bot_token: "{{ lookup('env', 'TELEGRAM_BOT_TOKEN') }}"
```

2. **Restrict access** to Alertmanager UI (port 9093)
3. **Use HTTPS** for production deployments
4. **Regularly rotate** bot tokens and app passwords 