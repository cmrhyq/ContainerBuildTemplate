FROM openjdk:8-jre-slim
MAINTAINER AlanHuang

ENV PARAMS="--spring.config.additional-location/config/application.yml"

ENV TZ=PRC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ADD ./xxl-job-executor*.jar /app.jar

ENTRYPOINT ["sh","-c","java -jar $JAVA_OPTS /app.jar $PARAMS"]