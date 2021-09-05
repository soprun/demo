SHELL := /bin/bash

# Self-Documented Makefile see https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.DEFAULT_GOAL := help


# Get the branch information from git
ifneq ($(shell which git),)
GIT_DATE := $(shell git log -n 1 --format="%ci")
GIT_HASH := $(shell git log -n 1 --format="%h")
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD | sed 's/[-_.\/]//g')
GIT_DEFAULT_BRANCH := main
GITINFO = .$(GIT_HASH).$(GIT_BRANCH)
else
GITINFO = ""
endif

OS = $(shell uname -s)

ifeq ($(shell echo $(OS) | egrep -c 'Darwin|FreeBSD|OpenBSD|DragonFly'),1)
DATE := $(shell date -j -r $(shell git log -n 1 --format="%ct") +%Y%m%d%H%M)
CPUS := $(shell sysctl hw.ncpu | awk '{print $$2}')
else
DATE := $(shell date --utc --date="$(GIT_DATE)" +%Y%m%d%H%M)
CPUS := $(shell nproc)
endif


.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

# https://github.com/phpdocker-io/phpdocker.io/blob/master/Makefile

BUILD_TAG ?= $(shell date +'%Y-%m-%d-%H-%M-%S')-$(shell git rev-parse --short HEAD)


USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)

PROJECT_DIR := $(shell cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
PROJECT_HOST_PATH := $(realpath $(PROJECT_HOST_PATH))


about: ## asd
	php bin/console about

env-vars: ## asd
	php bin/console debug:container --env-vars --show-hidden

echo-build-tag: ## echo-build-tag
	@echo $(DATE)

static-analysis: ## static-analysis
	@php -dxdebug.mode=develop,trace ./vendor/bin/phpstan \
		--ansi \
		--verbose \
		--generate-baseline \
		--xdebug \
		analyse

phpunit: ## unit-tests
	@php -dxdebug.mode=coverage ./vendor/bin/phpunit \
		--testdox \
		--colors=always

INFECTION_RUN := \
	./vendor/bin/infection \
		--test-framework=phpunit \
		--coverage=public/reports/infection \
		--threads=$(CPUS) \
		--force-progress \
		--formatter=progress \
		--skip-initial-tests \
		--ansi \
		--debug

CHANGED_FILES := $(shell git diff origin/main --diff-filter=AM --name-only | grep src/ | paste -sd "," -)

ifneq "$(CHANGED_FILES)" ""
  INFECTION_RUN += \
  	--filter="${CHANGED_FILES}" \
  	--ignore-msi-with-no-mutations
endif

changed-files:
	@echo "Files: $(CHANGED_FILES)"

mutation-tests: ## mutation-tests
	@php -dxdebug.mode=coverage $(INFECTION_RUN)

mutation-tests-phpdbg: ## mutation-tests
	@phpdbg -qrr $(INFECTION_RUN)

.PHONY: lint-container
lint-container:
	php bin/console lint:container

.PHONY: lint-twig
lint-twig:
	php bin/console lint:twig

composer-check:
	@## Validates a composer.json and composer.lock.
	@composer validate
	@## Check that platform requirements are satisfied.
	@composer check-platform-reqs;


deprecations:
	php bin/console debug:container --deprecations
