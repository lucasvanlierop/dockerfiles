FROM debian:jessie

MAINTAINER Lucas van Lierop <lucas@vanlierop.org>

RUN apt-get update && apt-get install -y \
    git-cola \
    libgnomeui-0 \
    libcanberra-gtk-module

ADD entrypoint.sh entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

CMD ["start"]
