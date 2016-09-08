FROM java:7

MAINTAINER Lucas van Lierop <lucas@vanlierop.org>

ENV VERSION 10.0.4

WORKDIR /opt

RUN curl \
        --location \
        --silent \
        --show-error \
        http://download.jetbrains.com/webide/PhpStorm-${VERSION}.tar.gz | tar xzv && \
        mv `realpath $(ls | grep PhpStorm-)` phpstorm && \
        ln -s ` realpath phpstorm/bin/phpstorm.sh` /usr/local/bin/phpstorm

ADD entrypoint.sh entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

CMD ["start"]
