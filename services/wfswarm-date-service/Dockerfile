# Build:
#   mvn clean package -DskipTests
#   docker build --rm -t wf-swarm-oauth:1.0.1 .
#   docker tag wf-swarm-oauth:1.0.1 docker.io/rhtgptetraining/wf-swarm-oauth:1.0.1

# Execute
#   docker run -t -i -p 91.0.1:8080 wf-swarm-oauth:1.0.1

# Docker push (on F28):
#   Make sure the following is the *first* entry in the docker daemon (by updating /etc/sysconfig/docker):  --add-registry docker.io
#   docker login docker.io -u rhtgptetraining
#   docker push docker.io/rhtgptetraining/wf-swarm-oauth:1.0.1




FROM redhat-openjdk-18/openjdk18-openshift:1.5-14
ENV JAVA_APP_DIR=/deployments
EXPOSE 8080 8778 9779
COPY target/wf-swarm-oauth-1.0.1-swarm.jar /deployments/
