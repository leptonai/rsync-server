# Security Policy: leptonai/rsync-server

## Reporting a Vulnerability

Do not open a public GitHub issue or pull request for a suspected vulnerability.

Report vulnerabilities privately through one of these channels:

1. **NVIDIA Vulnerability Disclosure Program (preferred):** [NVIDIA Product Security](https://www.nvidia.com/en-us/security/), using the [vulnerability report form](https://www.nvidia.com/en-us/security/report-vulnerability/).
2. **Email:** [psirt@nvidia.com](mailto:psirt@nvidia.com). Use the [NVIDIA public PGP key](https://www.nvidia.com/en-us/security/pgp-key) when the report contains sensitive evidence.
3. **GitHub private vulnerability reporting:** This repository's **Security** tab, then **Report a vulnerability**. If that option is not shown, use channel 1 or 2.

Include the repository name, the affected commit or image tag, the vulnerability type, reproduction steps, proof of concept if available, and the impact. Remove real passwords, addresses, and file contents from examples. Use the private channel to share anything that is itself sensitive.

NVIDIA PSIRT acknowledges receipt, validates the report, and coordinates remediation and disclosure. For this repository, remediation is a change to `Dockerfile` or `entrypoint.sh` on `main` and a rebuilt image. If the issue is in `rsync` itself or in code inherited unchanged from the upstream repository, say so in the report.

## Security Architecture and Context

`rsync-server` is a container image recipe for an `rsync` daemon. It is a fork of `axiom-data-science/rsync-server`. The fork removes the SSH server, moves the daemon to port 8873, and sets `use chroot = false` on the module. It is a service: a network file-transfer daemon packaged as a container. It contains no application code beyond a shell entrypoint.

The maintained copy is the `main` branch. There are no tags and no releases. The files are:

- `Dockerfile`: starts from `debian:bullseye-slim`, installs `rsync`, exposes port 8873, and runs `entrypoint.sh` as root.
- `entrypoint.sh`: writes `USERNAME:PASSWORD` to `/etc/rsyncd.secrets` with mode `0400`, generates `/etc/rsyncd.conf` unless one already exists, creates the volume directory, and starts `rsync --daemon`.
- `README.md`: usage examples that refer to an image in a public registry.
- `.github/workflows/docker.yml`: a build-and-push workflow inherited from the upstream repository. It targets the upstream image name, and it is not enabled in this fork at the time of writing.

The generated configuration defines one module, `volume`, at the path in `VOLUME` (default `/data`). The module is writable (`read only = false`), runs with `uid = root` and `gid = root`, sets `use chroot = false`, requires the user in `USERNAME`, denies all hosts except those in `ALLOW`, and caps the daemon at 10 connections with a 300-second timeout. The defaults are `USERNAME=user`, `PASSWORD=pass`, and `ALLOW` set to the private IPv4 ranges plus loopback. Logs go to standard output.

Its security responsibility is to limit read and write access to the mounted volume. The two controls are the rsync daemon's user and password check and the source-address allowlist.

The boundaries are TCP port 8873, which speaks the rsync daemon protocol without TLS; the environment variables read at container start; the mounted volume; and the container runtime that separates the root process from the host.

**Repository Exposure Classification:** Public. Basis: `github.com/leptonai/rsync-server` is a public GitHub repository; this document is written to public-safe detail.

**Service Exposure Classification:** External / Regulated (medium confidence). Basis: public source for a container image of a network daemon, with a public registry image named in `README.md`; this repository has no release process of its own and does not show where the image is deployed.

### Threat Model

1. **Default credentials:** `entrypoint.sh` falls back to `USERNAME=user` and `PASSWORD=pass`, and `README.md` includes examples that start the container without setting either. A container started that way gives read and write access to the volume to any client whose address matches `ALLOW`.
2. **Cleartext transport:** The rsync daemon protocol on port 8873 has no TLS. File contents and file names cross the network unencrypted, and the client cannot verify the server. The daemon's challenge-response login keeps the password itself off the wire, but it does not protect the data.
3. **Root writes without a chroot:** The `volume` module is writable, runs as `uid = root` and `gid = root`, and sets `use chroot = false`. The container also runs as root. An authenticated client can create files with any owner and mode, including setuid files, and confinement to the module path depends on rsync's own path and symlink handling. When the volume is a host directory, those files land on the host file system.
4. **The password is handled in the clear:** `PASSWORD` arrives as an environment variable, so it is visible in the container's configuration and in any orchestrator manifest that sets it. `entrypoint.sh` writes it unhashed to `/etc/rsyncd.secrets`.
5. **The address allowlist is broad by default:** The default `ALLOW` covers every private IPv4 range. Behind container networking, NAT, or a load balancer, client connections often appear to come from a private address, so the allowlist can match clients it was not meant to admit.
6. **Build inputs are not pinned:** `Dockerfile` refers to `debian:bullseye-slim` by tag and installs whatever `rsync` version that Debian release provides, so fixes to `rsync` arrive only when the image is rebuilt on a supported base. `docker.yml` refers to third-party actions by tag. `README.md` names a registry image that no workflow in this repository builds, so these files alone do not establish what that image contains.

### Critical Security Assumptions

- The operator sets a non-default `USERNAME` and `PASSWORD` and narrows `ALLOW` to the clients that need access.
- The network between clients and the container is trusted, or the connection runs inside an encrypted tunnel. Port 8873 is not exposed to the internet.
- The environment variables, and any `/etc/rsyncd.conf` already present in the container, come from a trusted operator. `entrypoint.sh` writes `USERNAME`, `ALLOW`, and `VOLUME` into the configuration without validation.
- Every client that can log in is trusted with root-level read and write access to the whole volume. The volume holds nothing those clients must not read or overwrite.
- The container runtime isolates the container's root user from the host, and a host directory used as the volume is not trusted for execution by other workloads.
- The Debian base image and its `rsync` package are trusted, and the image is rebuilt when either receives a security fix.

## Supported Versions

This repository has no tags and no releases. `main` is the only maintained copy. Security reports should name the commit, or the image tag and digest, not a version number.
