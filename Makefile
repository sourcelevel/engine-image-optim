.PHONY: image test

IMAGE_NAME ?= plataformatec/engine-image-optim

image:
	docker build --rm -t $(IMAGE_NAME) .

test: image
	docker run --rm $(IMAGE_NAME) rake

publish: image
	docker push $(IMAGE_NAME)
