.PHONY: help
.DEFAULT_GOAL := help

help:
				@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

prepare: build init ## Build docker images

build: ## Build containers
				docker-compose build --parallel

seed: migrate sync create_user ## Migrate and create

migrate:
				docker-compose run --rm backend sh -l -c 'bundle exec rake db:migrate'

sync:
				docker-compose run --rm backend sh -l -c "bundle exec rake cartodb:sync_tables[true] cartodb:connectors:create_providers"

create_user: ## Create user
				docker-compose run --rm backend sh -l -c 'script/create_dev_user "$$DEFAULT_USER_LOGIN" "$$DEFAULT_USER_PASSWORD" "$$DEFAULT_USER_EMAIL"'

run: ## Run all containers
				docker-compose up
