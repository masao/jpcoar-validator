IMAGE := jpcoar-validator
DOCKER := docker
RUBY_VERSION ?= 3.4

.PHONY: build test build-production run shell clean

# テスト用イメージ
build:
	$(DOCKER) build \
		--build-arg RUBY_VERSION=$(RUBY_VERSION) \
		--target test \
		-t $(IMAGE):test .

# RSpec
test: build
	$(DOCKER) run --rm $(IMAGE):test

# 本番相当のイメージ
build-production:
	$(DOCKER) build \
		--build-arg RUBY_VERSION=$(RUBY_VERSION) \
		--target production \
		-t $(IMAGE):production .

# ローカルで本番相当の Web サーバを起動
run: build-production
	$(DOCKER) run --rm -p 10000:10000 $(IMAGE):production

# コンテナ内でシェルを起動（Java サーバは起動しない）
shell: build
	$(DOCKER) run --rm -it \
		--entrypoint /bin/bash \
		$(IMAGE):test

# ローカルで作成した Docker イメージを削除
clean:
	-$(DOCKER) image rm $(IMAGE):test $(IMAGE):production