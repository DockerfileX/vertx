ARG JDK_VERSION

# 基础镜像
FROM --platform=${TARGETPLATFORM} nnzbz/temurinx:${JDK_VERSION}

# 作者及邮箱
# 镜像的作者和邮箱
LABEL maintainer="nnzbz@163.com"
# 镜像的描述
LABEL description="Environment for exec Vert.x Appication\
    为运行Vert.x而提供的环境"

# 设置工作目录
ENV WORKDIR=/usr/local/vertx
RUN mkdir -p ${WORKDIR}
WORKDIR ${WORKDIR}

# 设置Path环境变量
ENV PATH=/usr/local/vertx/bin:$PATH

# 复制文件
COPY add/config/* /usr/local/vertx/config
COPY add/lib/* /usr/local/vertx/lib

# 运行jar包的文件名
ENV MYSERVICE_FILE_NAME=myservice.jar

# 生成init.sh文件
RUN touch init.sh

# 生成entrypoint.sh文件
RUN echo '#!/bin/sh' >> entrypoint.sh
RUN echo 'set +e' >> entrypoint.sh
RUN echo 'sh ./init.sh' >> entrypoint.sh
# 判断是否启用ZooKeeper Cluster Manager
RUN echo 'echo "ZOOKEEPER_CLUSTER_MANAGER_ENABLE=${ZOOKEEPER_CLUSTER_MANAGER_ENABLE}"' >> entrypoint.sh
RUN echo 'if [[ ${ZOOKEEPER_CLUSTER_MANAGER_ENABLE} = "true" ]];then' >> entrypoint.sh
RUN echo '    rm -f /usr/local/vertx/lib/vertx-hazelcast-*' >> entrypoint.sh
RUN echo 'fi' >> entrypoint.sh
RUN echo 'echo "JAVA_OPTS=${JAVA_OPTS}"' >> entrypoint.sh
RUN echo 'CMD="vertx ${PROG_ARGS}"' >> entrypoint.sh
RUN echo 'echo "CMD=${CMD}"' >> entrypoint.sh
RUN echo '${CMD}' >> entrypoint.sh

# 授权执行
RUN chmod +x ./init.sh
RUN chmod +x ./entrypoint.sh

# 执行
ENTRYPOINT ["sh", "./entrypoint.sh"]
