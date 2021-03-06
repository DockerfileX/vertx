ARG VERSION
ARG JDK_VERSION=latest

FROM --platform=linux/amd64 vertx/vertx4:${VERSION} AS vertx

ARG JDK_VERSION
# 基础镜像
FROM --platform=${TARGETPLATFORM} nnzbz/openjdk:${JDK_VERSION}

# 作者及邮箱
# 镜像的作者和邮箱
LABEL maintainer="nnzbz@163.com"
# 镜像的描述
LABEL description="Environment for exec Vert.x Appication\
    为运行Vert.x而提供的环境"

# 设置工作目录
ENV WORKDIR=/usr/local/myservice
RUN mkdir -p ${WORKDIR}
WORKDIR ${WORKDIR}

# 复制vertx
COPY --from=vertx /usr/local/vertx /usr/local/vertx
ENV PATH=/usr/local/vertx/bin:$PATH

# 复制文件
COPY add/conf/log4j2.xml /usr/local/vertx/conf
COPY add/log4j2.component.properties /usr/local/vertx
COPY add/lib/* /usr/local/vertx/lib

# 运行jar包的文件名
ENV MYSERVICE_FILE_NAME=myservice.jar

RUN touch init.sh
RUN echo '#!/bin/sh' >> entrypoint.sh
RUN echo 'set +e' >> entrypoint.sh
RUN echo 'sh ./init.sh' >> entrypoint.sh
RUN echo 'CMD="vertx ${PROG_ARGS}"' >> entrypoint.sh
RUN echo 'echo $CMD' >> entrypoint.sh
RUN echo '$CMD' >> entrypoint.sh

RUN chmod +x ./init.sh
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["sh", "./entrypoint.sh"]
