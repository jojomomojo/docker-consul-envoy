.PHONY: build
DOCKER_REPOSITORY="letfn/consul-envoy"
DOCKER_VERSION="v1.8.0-v1.14.2"

build:
	docker build -t "${DOCKER_REPOSITORY}:${DOCKER_VERSION}" .

push:
	docker push "${DOCKER_REPOSITORY}:${DOCKER_VERSION}"
