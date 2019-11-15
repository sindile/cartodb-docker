.PHONY: help
.DEFAULT_GOAL := help

help:
				@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

prepare: build init ## Build docker images

build: ## Build containers
				docker-compose build --parallel

seed: ## Migrate and create
				docker-compose run --rm backend bundle exec rake db:migrate
				docker-compose run --rm backend bundle exec rake cartodb:sync_tables[true] cartodb:features:add_feature_flag['carto-connectors'] cartodb:features:enable_feature_for_all_users['carto-connectors'] cartodb:connectors:create_providers
				docker-compose run --rm backend sh -c 'script/create_dev_user "$$DEFAULT_USER_LOGIN" "$$DEFAULT_USER_PASSWORD" "$$DEFAULT_USER_EMAIL"'

run: ## Run all containers
				docker-compose up
