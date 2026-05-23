# Internal Tools Upgrade Pipeline

Automated upgrade system for internal tools at Creately. This engine safely upgrades various applications with version checking, comprehensive backups, and rollback capabilities.

## Supported Applications

| Application | Type | Upgrade Method |
|-------------|------|----------------|
| **Netdata** | Docker | Volume backups, container recreation |
| **Outline** | Docker | PostgreSQL backup, database migrations |
| **Gogs** | Binary | Filesystem backup, binary swap |
| **Asset Manager (Snipe-IT)** | Docker | Database backup, migrations, volume backups |
| **Appsmith** | Docker | AWS EC2 snapshots, credential handling |
| **Jenkins** | WAR | Home directory backup, WAR file replacement |

## 🔧 Configuration

### Environment Variables (.env)

Create a `.env` file in the `internal-tools-upgrade-engine` directory:

```bash
# AWS Credentials for Appsmith EC2 Snapshots
AWS_ACCESS_KEY_ID=your_aws_access_key_id_here
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key_here
AWS_DEFAULT_REGION=us-east-1

# Appsmith EC2 Volume IDs for Snapshots
APPSMITH_VOLUME_ID_1=vol-*****
APPSMITH_VOLUME_ID_2=vol-*****

# Slack Webhook URL for Notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Jenkins SSH Key
JENKINS_SSH_KEY=your_ssh_key_here
```

### Application Configuration (inventory/apps.yml)

Configure application-specific settings in `inventory/apps.yml`:

```yaml
apps:
  - name: appsmith
    host_group: appsmith
    type: docker
    upgrade_task: appsmith.yml
    compose_path: /opt/appsmith/docker-compose.yml
    healthcheck:
      type: http
      url: http://localhost
    rollback_supported: true
    aws:
      region: us-east-1
      instance_id: i-******
      volume_ids:
        - vol-*****  # Replace with actual volume IDs
        - vol-*****
```

### Host Configuration (inventory/hosts.ini)

Define target hosts in `inventory/hosts.ini`:

```ini
[gogs]
167.*.*.*

[outline]
128.*.*.*

[netdata]
128.*.*.*

[jenkins]
188.*.*.*

[asset_manager]
65.*.*.*

[appsmith]
192.*.*.*
```

## Features

### Version Management
- Automatic version comparison before upgrades
- Skips upgrades if already on latest version
- Supports multiple version sources (GitHub API, Docker Hub, Jenkins updates)

### Comprehensive Backups
- **Netdata**: Volume-level backups (config, lib, cache)
- **Outline**: PostgreSQL database + configuration files
- **Gogs**: Filesystem + database backups
- **Asset Manager**: Database mysqldump + volume backups
- **Appsmith**: AWS EC2 snapshots (multi-volume)
- **Jenkins**: WAR file + home directory backups

### Safety Mechanisms
- Pre-upgrade health checks
- Post-upgrade verification
- Automatic rollback on failure
- Detailed logging throughout process

### Health Checks
- HTTP endpoint validation
- Container health status
- Service status verification
- Application-specific health endpoints

## Usage

### Jenkins Pipeline

The system is designed to run via Jenkins. Configure the pipeline in Jenkins with:

1. **Credentials**:
   - `slack-webhook`: Slack webhook URL
   - `hetzner_tools_prod`: SSH key for remote host access

2. **Environment Variables**: Configure via `.env` file or Jenkins environment variables

3. **Run**: Execute the Jenkins pipeline to upgrade all configured applications

### Manual Execution

For testing or manual upgrades:

```bash
# Load environment variables
source .env

# Run specific playbook
ansible-playbook playbooks/main.yml \
  -i inventory/hosts.ini \
  --limit appsmith \
  -e target_app=appsmith \
  -e "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" \
  -e "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
```

## Security

- **.env file**: Contains sensitive credentials and is excluded from git via `.gitignore`
- **SSH keys**: Managed via Jenkins credentials
- **AWS credentials**: Loaded from environment variables, never hardcoded in playbooks
- **Backup retention**: Configurable per application

## Logging

Logs are stored in the `logs/` directory with timestamps:
- `logs/upgrade_<BUILD_NUMBER>.log`: Jenkins pipeline logs
- `/var/log/internal-tools-upgrade/`: Server-side logs (when applicable)

## Rollback Procedures

Each application has automatic rollback on failure:

- **Docker apps**: Restore compose files and previous images
- **Binary apps**: Restore previous binaries
- **Database apps**: Restore from SQL backups
- **AWS apps**: Restore from EC2 snapshots

Manual rollback is also supported via backup files created during upgrade.

## Troubleshooting

### Common Issues

1. **AWS Credentials**: Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set correctly
2. **SSH Access**: Ensure Jenkins can SSH to target hosts
3. **Disk Space**: Verify sufficient space for backups
4. **Version Conflicts**: Check version comparison logic if upgrades aren't triggering

### Debug Mode

Enable debug logging by setting `DEBUG=true`:
```bash
export DEBUG=true
```

## Maintenance

### Regular Tasks
- Update `.env` file with new credentials when they change
- Review and update application configurations in `inventory/apps.yml`
- Monitor backup storage and implement cleanup policies
- Update playbook procedures when applications change

### Version Updates
The system automatically checks for new versions from:
- GitHub API (for most applications)
- Docker Hub (for Docker images)
- Jenkins updates API (for Jenkins itself)

## Support

For issues or questions:
- Check logs in `logs/` directory
- Review application-specific playbook procedures
- Verify environment variables are correctly set
- Ensure SSH and AWS credentials are valid



