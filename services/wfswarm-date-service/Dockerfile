# Build:
#   docker build --rm -t wf-swarm-oauth:1.0 .
#   docker tag wf-swarm-oauth:1.0 docker.io/rhtgptetraining/wf-swarm-oauth:1.0

# Docker push (on F28):
#   Make sure the following is the *first* entry in the docker daemon (by updating /etc/sysconfig/docker):  --add-registry docker.io
#   docker login docker.io -u rhtgptetraining
#   docker push docker.io/rhtgptetraining/wf-swarm-oauth:1.0




FROM fabric8/java-jboss-openjdk8-jdk:1.3.1
ENV JAVA_APP_DIR=/deployments
EXPOSE 8080 8778 9779
COPY target/wf-swarm-oauth-1.0-swarm.jar /deployments/
