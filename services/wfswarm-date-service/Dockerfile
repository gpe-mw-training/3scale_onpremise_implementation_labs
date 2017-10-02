# Usage 
# Build
#   mvn clean package 
#   docker pull fabric8/java-centos-openjdk8-jdk
#   docker build --rm -t docker.io/rhtgptetraining/wf_swarm_datestamp_service:1.0 .
#
# Execute
#   docker run -t -i -p 9180:8080 docker.io/rhtgptetraining/wf_swarm_datestamp_service:1.0
#
# Test
#   curl http://$HOSTNAME:9180/time/now
#
# Push to docker hub
#   docker push docker.io/rhtgptetraining/wf_swarm_datestamp_service:1.0

FROM centos:7

USER root

ENV SWARM_FILE wf-swarm-swagger-1.0-swarm.jar
ENV JAVA_APP_DIR /opt
ENV APP_LISTENER_PORT 8080

# /dev/urandom is used as random source, which is prefectly safe
# according to http://www.2uo.de/myths-about-urandom/
RUN yum install -y \
       java-1.8.0-openjdk  \
       java-1.8.0-openjdk-devel \
    && echo "securerandom.source=file:/dev/urandom" >> /usr/lib/jvm/java/jre/lib/security/java.security


ENV JAVA_HOME /etc/alternatives/jre

EXPOSE 8080

COPY target/$SWARM_FILE $JAVA_APP_DIR

ENTRYPOINT ["sh", "-c"]
CMD [ "java -Dswarm.http.port=$APP_LISTENER_PORT -jar $JAVA_APP_DIR/$SWARM_FILE" ]
