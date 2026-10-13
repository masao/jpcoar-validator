IMAGE := jpcoar-validator
DOCKER := docker

.PHONY: build test run shell clean

# CI 用イメージ
build:
	$(DOCKER) build --target test -t $(IMAGE):test .

# RSpec
test: build
	$(DOCKER) run --rm $(IMAGE):test

# 本番相当のイメージ
build-production:
	$(DOCKER) build --target production -t $(IMAGE):production .

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