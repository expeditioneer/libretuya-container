# LibreTiny Container

[![Docker Repository on Quay](https://quay.io/repository/expeditioneer/libretiny/status "Docker Repository on Quay")](https://quay.io/repository/expeditioneer/libretiny)

Based on RedHat UBI-9 Image.

## Scope
Goal of this repository is to create a container which runs as smooth as possible on OpenShift.
This container enables pass-through TLS termination to protect also internal traffic.

## Configuration

### Environment Variables
- `DASHBOARD_USER` sets the username for the dashboard login
- `DASHBOARD_PASSWORD` sets the password for the dashboard login

If not set the Dashboard will be accessible without any protection. 

### Volumes
Persistence for configuration files, should be mounted to _/etc/libretiny_ inside the container.

### Secrets
To protect internal traffic with TLS provide a secret for `server.crt` and `server.key` can be provided.
The locations should be `/etc/pki/libretiny/server.crt` and `/etc/pki/libretiny/private/server.key` for the container/pod.

#### Example configuration
```yaml
spec:
  template:
    spec:
      containers:
        - name: libretiny
          volumeMounts:
            - name: libretiny-tls
              mountPath: /etc/pki/libretiny/
      volumes:
        - name: libretiny-tls
          secret:
            defaultMode: 420
            secretName: libretiny-tls
            items:
              - key: tls.crt
                path: server.crt
              - key: tls.key
                path: private/server.key
```

### Repetitive Logic
Should be run as cron job with attached persistent storage for `/etc/libretiny`
`pio system prune --force`
