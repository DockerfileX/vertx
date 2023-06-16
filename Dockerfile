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
ENV WORKDIR=/usr/local/vertx
RUN mkdir -p ${WORKDIR}
WORKDIR ${WORKDIR}

# 复制vertx
COPY --from=vertx /usr/local/vertx /usr/local/vertx
ENV PATH=/usr/local/vertx/bin:$PATH

# 删除冲突的配置文件
RUN rm -rf /usr/local/vertx/conf/default-cluster.xml
RUN rm -rf /usr/local/vertx/conf/logging.properties

# 删除旧的不兼容的jar包
RUN rm -rf /usr/local/vertx/lib/hazelcast-*
# RUN rm -rf /usr/local/vertx/lib/netty-*
RUN rm -rf /usr/local/vertx/lib/bcpkix-jdk15on-*
RUN rm -rf /usr/local/vertx/lib/bcprov-jdk15on-*
RUN rm -rf /usr/local/vertx/lib/slf4j-*
RUN rm -rf /usr/local/vertx/lib/jackson-*
RUN rm -rf /usr/local/vertx/lib/guava-*
RUN rm -rf /usr/local/vertx/lib/checker-qual-*
RUN rm -rf /usr/local/vertx/lib/error_prone_annotations-*
RUN rm -rf /usr/local/vertx/lib/failureaccess-*
RUN rm -rf /usr/local/vertx/lib/j2objc-annotations-*
RUN rm -rf /usr/local/vertx/lib/jsr305-*
RUN rm -rf /usr/local/vertx/lib/listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.jar
RUN rm -rf /usr/local/vertx/lib/zookeeper-*
RUN rm -rf /usr/local/vertx/lib/commons-io-*
RUN rm -rf /usr/local/vertx/lib/curator-*
RUN rm -rf /usr/local/vertx/lib/commons-io-*
RUN rm -rf /usr/local/vertx/lib/ojdbc11-*

# 复制文件
COPY add/conf/* /usr/local/vertx/conf
COPY add/lib/*.jar /usr/local/vertx/lib
COPY add/skywalking-agent /usr/local/vertx/skywalking-agent

# 运行jar包的文件名
ENV MYSERVICE_FILE_NAME=myservice.jar

# 生成init.sh文件
RUN touch init.sh

# 生成entrypoint.sh文件
RUN echo '#!/bin/sh' >> entrypoint.sh
RUN echo 'set +e' >> entrypoint.sh
RUN echo 'sh ./init.sh' >> entrypoint.sh
# 判断是否启用ZooKeeper Cluster Manager
RUN echo 'echo "ENABLE_ZOOKEEPER_CLUSTER_MANAGER=${ENABLE_ZOOKEEPER_CLUSTER_MANAGER}"' >> entrypoint.sh
RUN echo 'if [[ ${ENABLE_ZOOKEEPER_CLUSTER_MANAGER} = "true" ]];then' >> entrypoint.sh
RUN echo '    rm -f /usr/local/vertx/lib/vertx-hazelcast-*' >> entrypoint.sh
RUN echo 'fi' >> entrypoint.sh
# 判断是否启用SkyWalking Agent
RUN echo 'echo "ENABLE_SKYWALKING_AGENT=${ENABLE_SKYWALKING_AGENT}"' >> entrypoint.sh
RUN echo 'if [[ ${ENABLE_SKYWALKING_AGENT} = "true" ]];then' >> entrypoint.sh
RUN echo '    JAVA_OPTS="-javaagent:/usr/local/vertx/skywalking-agent/skywalking-agent.jar ${JAVA_OPTS}"' >> entrypoint.sh
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
