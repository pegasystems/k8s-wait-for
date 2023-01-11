TAG = latest
USER_NAME = $(shell git config --get remote.origin.url | sed 's/\.git$$//' | tr ':.' '/' | rev | cut -d '/' -f 2 | rev)
REPO_NAME = $(shell git config --get remote.origin.url | sed 's/\.git$$//' | tr ':.' '/' | rev | cut -d '/' -f 1 | rev)
TARGET := $(if $(TARGET),$(TARGET),$(shell ./evaluate_platform.sh))
VCS_REF = $(shell git rev-parse --short HEAD)
BUILD_DATE = $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
BUILD_FLAGS := $(if $(BUILD_FLAGS),$(BUILD_FLAGS),--load --no-cache)
BUILDER_NAME = k8s-wait-for-builder
NON_ROOT_DOCKERFILE = DockerfileNonRoot
DOCKER_TAGS = pegasystems/$(REPO_NAME):$(TAG_PREFIX)latest pegasystems/$(REPO_NAME):$(TAG_PREFIX)$(TAG) pegasystems/$(REPO_NAME):$(TAG_PREFIX)test
PREFIX = $(shell git config --get remote.origin.url | tr ':.' '/'  | rev | cut -d '/' -f 3 | rev)

all: image

container: image

image:
	docker build -t $(PREFIX)/$(REPO_NAME) . # Build new image and automatically tag it as latest
	docker tag $(PREFIX)/$(REPO_NAME) $(PREFIX)/$(REPO_NAME):$(TAG)  # Add the version tag to the latest image

push: image
	docker push $(PREFIX)/$(REPO_NAME):latest # Push image tagged as latest to repository

clean:
	docker rmi $(PREFIX)/$(REPO_NAME)
	docker rmi $(PREFIX)/$(REPO_NAME):$(TAG)
	docker rmi $(PREFIX)/$(REPO_NAME):test

test: image
        docker tag $(PREFIX)/$(REPO_NAME) $(PREFIX)/$(REPO_NAME):test  # Add a tag for the current image to be tested