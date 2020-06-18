.PHONY: build
DOCKER_REPOSITORY="letfn/consul-envoy"
DOCKER_VERSION="v1.8.0-rc1-v0.14.1"

build:
	docker build -t "${DOCKER_REPOSITORY}:${DOCKER_VERSION}" .
