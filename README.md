# Vert.x

## 1. 简介

Environment for **Vert.x** Appication

为运行 **Vert.x** 应用而提供的环境

## 2. 特性

1. Alpine
2. OpenJDK 18
3. Vert.x 4.3.5
4. TZ=Asia/Shanghai
5. C.UTF-8
6. curl和telnet
7. arthas(在/usr/local/arthas目录下)
8. 运行的jar包：/usr/local/vertx/lib/myservice.jar

## 3. 编译并上传镜像

```sh
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:4.3.5 --build-arg VERSION=4.3.5 --build-arg JDK_VERSION=18 . --push
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:4.3.5-alpine --build-arg VERSION=4.3.5 --build-arg JDK_VERSION=alpine . --push
# latest
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:latest --build-arg VERSION=4.3.5 --build-arg JDK_VERSION=18 . --push
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:alpine --build-arg VERSION=4.3.5 --build-arg JDK_VERSION=alpine . --push
```

## 4. 单机

```sh
docker run -d --init --restart=always \
  --log-opt max-size=50m
  -e PROG_ARGS=run xxx.xxx.verticle.MainVerticle -cp conf/*:lib/*.jar --ha -Dhazelcast.logging.type=slf4j --launcher-class=io.vertx.core.Launcher \
  -e JAVA_OPTS=--add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED --add-opens java.base/sun.net=ALL-UNNAMED \
  -v /usr/local/xxx-svr/conf/:/usr/local/vertx/conf/:z \
  -v /var/log/xxx-svr/:/usr/local/vertx/logs/:z \
  -v /usr/local/xxx-svr/xxx-svr-x.x.x-jar-with-dependencies.jar:/usr/local/vertx/lib/myservice.jar:z \
  --net=host \
  --name 容器名称 nnzbz/vertx:4.3.5
```

## 5. Swarm

```sh
mkdir /usr/local/bin,conf,stack,log/xxx-svr
vi /usr/local/stack/xxx-svr-stack.yml
```

- Docker Compose

```yaml{.line-numbers}
version: "3.9"
services:
  svr:
    image: nnzbz/vertx:4.3.5
    init: true
    environment:
      - PROG_ARGS=run xxx.xxx.verticle.MainVerticle -cp conf/*:lib/*.jar --ha -Dhazelcast.logging.type=slf4j --launcher-class=io.vertx.core.Launcher
      - JAVA_OPTS=--add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED --add-opens java.base/sun.net=ALL-UNNAMED
      #- Xms100M -Xmx100M
      # 设置Log4j2使用异步日志
      #- Log4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector
    volumes:
      # 初始化执行的脚本
      #- /usr/local/vertx/init.sh:/usr/local/vertx/init.sh:z
      # 配置文件
      - /usr/local/conf/xxx-svr-config.json:/usr/local/vertx/conf/config.json:z
      - /usr/local/conf/vertx-default-jul-logging.properties:/usr/local/vertx/conf/vertx-default-jul-logging.properties
      # 配置日志目录(注意要先创建目录/var/log/xxx-svr/)
      - /var/log/xxx-svr/:/usr/local/vertx/logs/:z
      # 外部jar包
      - /usr/local/lib/xxx.jar:/usr/local/vertx/lib/xxx.jar:z
      # 运行的jar包
      - /usr/local/bin/xxx-svr-x.x.x-jar-with-dependencies.jar:/usr/local/vertx/lib/myservice.jar:z
    logging:
      options:
        max-size: 50m
    deploy:
      placement:
        constraints:
          # 部署的节点指定是app角色的
          - node.labels.role==app
      # 默认副本数先设置为1，启动好后再用 scale 调整，以防第一次启动初始化时并发建表
      replicas: 1

networks:
  default:
    external: true
    name: rebue
```

- 部署

```sh
docker stack deploy -c /usr/local/xxx-svr/stack.yml xxx
```
