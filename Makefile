TAG = latest
USER_NAME = $(shell git config --get remote.origin.url | sed 's/\.git$$//' | tr ':.' '/' | rev | cut -d '/' -f 2 | rev)
REPO_NAME = $(shell git config --get remote.origin.url | sed 's/\.git$$//' | tr ':.' '/' | rev | cut -d '/' -f 1 | rev)
TARGET := $(if $(TARGET),$(TARGET),$(shell ./evaluate_platform.sh))
VCS_REF = $(shell git rev-parse --short HEAD)
BUILD_DATE = $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
BUILD_FLAGS := $(if $(BUILD_FLAGS),$(BUILD_FLAGS),--load --no-cache)
BUILDER_NAME = k8s-wait-for-builder
DOCKER_TAGS = ganga3/k8s-wait-for:latest ganga3/k8s-wait-for:$(TAG)

all: push

images: image

image:
	@echo TARGET IS $(TARGET)
	if ! docker buildx inspect $(BUILDER_NAME) 2> /dev/null ; then docker buildx create --name $(BUILDER_NAME) ; fi
	docker buildx build \
		--builder=$(BUILDER_NAME) \
		--platform=$(TARGET) \
		--build-arg VCS_REF=$(VCS_REF) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		$(BUILD_FLAGS) \
		$(foreach TAG,$(DOCKER_TAGS),--tag $(TAG)) \
		.

push: BUILD_FLAGS := $(BUILD_FLAGS:--load=)
push: BUILD_FLAGS += --push
push: image

clean:
	if docker buildx inspect $(BUILDER_NAME) 2> /dev/null ; then docker buildx rm $(BUILDER_NAME) ; fi
	$(foreach TAG,$(DOCKER_TAGS),docker rmi -f $(TAG); )