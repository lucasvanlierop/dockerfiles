FROM java:8

MAINTAINER Lucas van Lierop <lucas@vanlierop.org>

ENV VERSION 2016.2.3

RUN apt-get update && apt-get install -y libcanberra-gtk-module

WORKDIR /opt

RUN curl \
        --location \
        --silent \
        --show-error \
        https://download.jetbrains.com/idea/ideaIU-$VERSION.tar.gz | tar xzv && \
        mv `realpath $(ls | grep idea-)` intellij && \
        ln -s ` realpath intellij/bin/idea.sh` /usr/local/bin/intellij

ADD entrypoint.sh entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

CMD ["start"]
