# rsync-server

A `rsyncd` server in Docker. You know, for moving files.

## Quickstart

Start a server 

```shell
docker run \
    --name rsync-server \
    -p 8000:8873 \
    -p 9000:22 \
    -e USERNAME=user \
    -e PASSWORD=pass \
    public.ecr.aws/n0k2r8k8/rsyncd:latest
```

**Warning** If you are exposing services to the internet be sure to change the default password from `pass` by settings the environmental variable `PASSWORD`.

### `rsyncd`

Please note that `/volume` is the `rsync` volume pointing to `/data`. The data
will be at `/data` in the container. Use the `VOLUME` parameter to change the
destination path in the container. Even when changing `VOLUME`, you will still
`rsync` to `/volume`. **It is recommended that you always change the default password of `pass` by setting the `PASSWORD` environmental variable, even if you are using key authentication.**

```shell
rsync -av /your/folder/ rsync://user@localhost:8000/volume
Password: pass

sending incremental file list
./
foo/
foo/bar/
foo/bar/hi.txt

sent 166 bytes  received 39 bytes  136.67 bytes/sec
total size is 0  speedup is 0.00
```

## Usage

Variable options (on run)

* `USERNAME` - the `rsync` username. defaults to `user`
* `PASSWORD` - the `rsync` password. defaults to `pass`
* `VOLUME`   - the path for `rsync`. defaults to `/data`
* `ALLOW`    - space separated list of allowed sources. defaults to `10.0.0.0/8 192.168.0.0/16 172.16.0.0/12 127.0.0.1/32`.

### Simple server on port 8873

```shell
docker run -p 873:8873 public.ecr.aws/n0k2r8k8/rsyncd:latest
```

### Use a volume for the default `/data`

```shell
docker run -p 873:8873 -v /your/folder:/data public.ecr.aws/n0k2r8k8/rsyncd:latest
```

### Set a username and password

```shell
docker run \
    -p 873:8873 \
    -v /your/folder:/data \
    -e USERNAME=admin \
    -e PASSWORD=mysecret \
    public.ecr.aws/n0k2r8k8/rsyncd:latest
```

### Run on a custom port

```shell
docker run \
    -p 9999:8873 \
    -v /your/folder:/data \
    -e USERNAME=admin \
    -e PASSWORD=mysecret \
    public.ecr.aws/n0k2r8k8/rsyncd:latest
```

```shell
rsync rsync://admin@localhost:9999

volume            /data directory
```

### Modify the default volume location

```shell
docker run \
    -p 9999:8873 \
    -v /your/folder:/myvolume \
    -e USERNAME=admin \
    -e PASSWORD=mysecret \
    -e VOLUME=/myvolume \
    public.ecr.aws/n0k2r8k8/rsyncd:latest
```

```shell
rsync rsync://admin@localhost:9999

volume            /myvolume directory
```

### Allow specific client IPs

```shell
docker run \
    -p 9999:8873 \
    -v /your/folder:/myvolume \
    -e USERNAME=admin \
    -e PASSWORD=mysecret \
    -e VOLUME=/myvolume \
    -e ALLOW=192.168.24.0/24 \
    public.ecr.aws/n0k2r8k8/rsyncd:latest
```
