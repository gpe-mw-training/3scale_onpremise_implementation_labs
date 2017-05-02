# Usage 
# Build
#   mvn clean package
#   docker build --rm -t docker.io/rhtgptetraining/vertx-greeting-service:1.0 .
#
# Execute
#   docker run -t -i -p 9080:8080 docker.io/rhtgptetraining/vertx-greeting-service:1.0
#
# Test
#   curl -l $HOSTNAME:9080/hello
#
# Push to docker hub
#   docker push docker.io/rhtgptetraining/vertx-greeting-service:1.0


# Extend vert.x image
FROM vertx/vertx3

ENV VERTICLE_NAME io.vertx.blog.App
ENV VERTICLE_FILE target/vertx-raml-1.0-fat.jar

# Set the location of the verticles
ENV VERTICLE_HOME /usr/verticles

EXPOSE 8080

COPY $VERTICLE_FILE $VERTICLE_HOME/

# Launch the verticle
WORKDIR $VERTICLE_HOME
ENTRYPOINT ["sh", "-c"]
CMD ["exec vertx run $VERTICLE_NAME -cp $VERTICLE_HOME/*"]
