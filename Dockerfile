FROM debian:bullseye-slim
ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
ENV NOTVISIBLE "in users profile"

RUN apt-get update && \
    apt-get install -y --no-install-recommends rsync && \
    apt-get clean && \
    echo "export VISIBLE=now" >> /etc/profile && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /entrypoint.sh

EXPOSE 8873
USER root

ENTRYPOINT ["/entrypoint.sh"]
CMD ["rsync_server"]
