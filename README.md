# Vert.x

## 1. 简介

Environment for **Vert.x** Appication

为运行 **Vert.x** 应用而提供的环境

## 2. 特性

1. Alpine
2. OpenJDK 18
3. Vert.x 4.3.8
4. TZ=Asia/Shanghai
5. C.UTF-8
6. curl和telnet
7. arthas(在/usr/local/arthas目录下)
8. 运行的jar包：/usr/local/vertx/lib/myservice.jar

## 3. 编译并上传镜像

```sh
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:4.3.8 --build-arg VERSION=4.3.8 --build-arg JDK_VERSION=18 . --push
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:4.3.8-alpine --build-arg VERSION=4.3.8 --build-arg JDK_VERSION=alpine . --push
# latest
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:latest --build-arg VERSION=4.3.8 --build-arg JDK_VERSION=18 . --push
docker buildx build --platform linux/arm64,linux/amd64 -t nnzbz/vertx:alpine --build-arg VERSION=4.3.8 --build-arg JDK_VERSION=alpine . --push
```

## 4. Swarm

```sh
mkdir /usr/local/bin,conf,stack,log/xxx-svr
vi /usr/local/stack/xxx-svr-stack.yml
```

```yaml{.line-numbers}
version: "3.9"
services:
  svr:
    image: nnzbz/vertx:4.3.8
    init: true
    environment:
      - PROG_ARGS=run xxx.xxx.verticle.MainVerticle -cp conf/*:lib/*.jar --options conf/vertx-option.json --ha --hagroup xxx
      - JAVA_OPTS=--add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED --add-opens java.base/sun.net=ALL-UNNAMED
      #- Xms100M -Xmx100M
      # 设置vertx日志使用slf4j
      - vertx.logger-delegate-factory-class-name=io.vertx.core.logging.SLF4JLogDelegateFactory
      # 设置hazelcast日志使用slf4j
      - hazelcast.logging.type=slf4j
      # jul to log4j
      #- java.util.logging.manager=org.apache.logging.log4j.jul.LogManager
      # 设置Log4j2使用异步日志
      #- Log4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector
    volumes:
      # 初始化执行的脚本
      #- /usr/local/stack/init.sh:/usr/local/vertx/init.sh:z
      # 配置文件
      - /usr/local/conf/xxx-svr-config.json:/usr/local/vertx/conf/config.json:z
      - /usr/local/conf/vertx-option.json:/usr/local/vertx/conf/vertx-option.json:z
      - /usr/local/conf/cluster.xml:/usr/local/vertx/conf/cluster.xml:z
      - /usr/local/conf/zookeeper.json:/usr/local/vertx/conf/zookeeper.json:z
      #- /usr/local/conf/log4j2.xml:/usr/local/vertx/conf/log4j2.xml:z
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

- /usr/local/conf/xxx-svr-config.json

```json
{
    "stores": [
        {
            "type": "git",
            "config": {
                "url": "http://gitea_svr:3000/vertx/vertx-config.git",
                "branch": "main",
                "user": "vertx",
                "password": "********",
                "path": "local",
                "filesets": [
                    {
                        "pattern": "xxx.yml",
                        "format": "yaml"
                    }
                ]
            }
        }
    ]
}
```

- /usr/local/conf/vertx-option.json

```json
{
    "preferNativeTransport": true
}
```

- /usr/local/conf/cluster.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!--
  ~ Copyright 2017 Red Hat, Inc.
  ~
  ~ Red Hat licenses this file to you under the Apache License, version 2.0
  ~ (the "License"); you may not use this file except in compliance with the
  ~ License.  You may obtain a copy of the License at:
  ~
  ~ http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
  ~ WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
  ~ License for the specific language governing permissions and limitations
  ~ under the License.
  -->

<hazelcast xmlns="http://www.hazelcast.com/schema/config"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xsi:schemaLocation="http://www.hazelcast.com/schema/config
           https://www.hazelcast.com/schema/config/hazelcast-config-4.2.xsd">

  <network>
    <join>
      <multicast/>
    </join>
  </network>

  <multimap name="__vertx.subs">
    <backup-count>1</backup-count>
    <value-collection-type>SET</value-collection-type>
  </multimap>

  <map name="__vertx.haInfo">
    <backup-count>1</backup-count>
  </map>

  <map name="__vertx.nodeInfo">
    <backup-count>1</backup-count>
  </map>

  <cp-subsystem>
    <cp-member-count>3</cp-member-count>
    <semaphores>
      <semaphore>
        <name>__vertx.*</name>
        <jdk-compatible>false</jdk-compatible>
        <initial-permits>1</initial-permits>
      </semaphore>
    </semaphores>
  </cp-subsystem>

</hazelcast>
```

- /usr/local/conf/zookeeper.json

```json
{
  "zookeeperHosts": "zoo:2181",
  "sessionTimeout": 20000,
  "connectTimeout": 3000,
  "rootPath": "io.vertx",
  "retry": {
    "initialSleepTime": 100,
    "intervalTimes": 10000,
    "maxTimes": 5
  }
}
```

- 部署

```sh
docker stack deploy -c /usr/local/xxx-svr/stack.yml xxx
```
