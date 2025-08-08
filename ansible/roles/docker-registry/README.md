# Docker Registry Ansible Role

This role deploys a private Docker registry using Docker Compose, with support for S3 as a storage backend.

## Requirements

- Docker and Docker Compose must be installed on the target host.
- Access to an S3 bucket with valid credentials.

## Role Variables

Available variables are listed in `defaults/main.yml`. Key variables include:

- `docker_registry_data_dir`: The directory on the host to store the `docker-compose.yml` file. Default is `/opt/docker-registry`.
- `docker_registry_image`: The Docker image to use for the registry. Default is `registry:2`.
- `docker_registry_port`: The host port to expose the registry on. Default is `5000`.
- `docker_registry_s3_region`: The AWS region for the S3 bucket.
- `docker_registry_s3_bucket`: The name of the S3 bucket for storage.
- `docker_registry_s3_access_key`: The AWS access key for the S3 bucket.
- `docker_registry_s3_secret_key`: The AWS secret key for the S3 bucket.
- `docker_registry_s3_region_endpoint`: The region endpoint for S3-compatible storage (optional).

## Dependencies

None.

## Example Playbook

```yaml
- hosts: registry_servers
  become: true
  roles:
    - role: docker
    - role: docker-registry
      vars:
        docker_registry_s3_bucket: "my-production-registry"
```

## License

MIT

## Author Information

This role was created by an AI assistant. 