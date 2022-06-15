# Vert.x

## 1. 简介

Environment for **Vert.x** Appication

为运行 **Vert.x** 应用而提供的环境

## 2. 特性

1. Alpine
2. OpenJDK 18
3. Vert.x 4.3.1
4. TZ=Asia/Shanghai
5. C.UTF-8
6. curl和telnet
7. arthas(在/usr/local/arthas目录下)
8. 运行的jar包：/usr/local/myservice/myservice.jar

## 3. 编译并上传镜像

```sh
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:4.3.1 --build-arg VERSION=4.3.1 --build-arg JDK_VERSION=18 . --push
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:4.3.1-alpine --build-arg VERSION=4.3.1 --build-arg JDK_VERSION=alpine . --push
# latest
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:latest --build-arg VERSION=4.3.1 --build-arg JDK_VERSION=18 . --push
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:alpine --build-arg VERSION=4.3.1 --build-arg JDK_VERSION=alpine . --push
```

## 4. 单机

```sh
docker run -d --net=host --name 容器名称 --init -v /usr/local/外部程序所在目录:/usr/local/myservice --restart=always nnzbz/vertx
```

## 5. Swarm

- Docker Compose

```yaml{.line-numbers}
version: "3.9"
services:
  svr:
    image: nnzbz/vertx
    init: true
    environment:
      - PROG_ARGS=run myvertx.gatex.verticle.MainVerticle -cp conf/*:lib/*.jar:myservice.jar --redeploy=myservice.jar,conf/* --ha -Dhazelcast.logging.type=slf4j --launcher-class=io.vertx.core.Launcher
      - JAVA_OPTS=--add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED
        #-Xms100M -Xmx100M
    volumes:
      # 配置文件目录
      - /usr/local/xxx-svr/conf/:/usr/local/myservice/conf/:z
      # 配置日志目录(注意要先创建目录/var/log/xxx-svr/)
      - /var/log/xxx-svr/:/usr/local/myservice/logs/:z
      # lib目录(存放外部jar包)
      - /usr/local/xxx-svr/lib/:/usr/local/myservice/lib/:z
      # 运行的jar包
      - /usr/local/xxx-svr/xxx-svr-x.x.x-fat.jar:/usr/local/myservice/myservice.jar:z
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
