FROM ruby:2.4.0-onbuild

# Build:
#   docker build --rm -t oidc_client:1.0 .
#   docker tag oidc_client:1.0 docker.io/rhtgptetraining/oidc_client:1.0

# Execution: docker
#   docker run --rm oidc_client:1.0 

# Execution: OpenShift
#   oc run oidc_client --image=docker.io/rhtgptetraining/oidc_client:1.0

MAINTAINER Maria Pilar Guerra Arias <pguerra@redhat.com>

EXPOSE 3000
CMD ["bundle", "exec", "rackup", "--port", "3000", "--host", "0.0.0.0"]
