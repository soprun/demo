SHELL := /bin/bash

# Self-Documented Makefile see https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.DEFAULT_GOAL := help

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-27s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

# https://github.com/phpdocker-io/phpdocker.io/blob/master/Makefile

BUILD_TAG ?= $(shell date +'%Y-%m-%d-%H-%M-%S')-$(shell git rev-parse --short HEAD)


about: ## asd
	php bin/console about

env-vars: ## asd
	php bin/console debug:container --env-vars --show-hidden



echo-build-tag: ## echo-build-tag
	@echo $(BUILD_TAG)

static-analysis: ## static-analysis
	php ./vendor/bin/phpstan --ansi -v analyse -l 8 src

unit-tests: ## unit-tests
	php ./vendor/bin/phpunit --testdox --colors=always

coverage-tests: ## coverage-tests
	php -dxdebug.mode=coverage ./vendor/bin/phpunit \
		--testdox \
		--colors=always

mutation-tests: ## mutation-tests
	php -dxdebug.mode=coverage ./vendor/bin/infection \
		--test-framework=phpunit \
		--coverage=public/reports/infection \
		--threads=4 \
		--skip-initial-tests

mutation-tests-phpdbg: ## mutation-tests
	phpdbg -qrr ./vendor/bin/infection \
		--test-framework=phpunit \
		--coverage=public/reports/infection \
		--threads=4 \
		--skip-initial-tests


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