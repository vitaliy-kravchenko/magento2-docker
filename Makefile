# import environment variables
env ?= local
env_file := env/$(env).build.env
# build_args := $(shell for i in `cat $(env_file)`; do echo "--build-arg $$i"; done)
build_args := -i --rm --env-file ${env_file} -v $${PWD}/magento2:/var/www/magento2 --network magento2 magento2php:latest

all: build up

build:
	@[[ -f ./php-fpm/auth.json ]] || { echo '\nCreate magento repo auth file first ./php-fpm/auth.json\n'; exit 1; }
	
	@echo "\n\033[92m--> Build php-fpm container\033[0m\n"
	docker build -t magento2php:latest ./php-fpm
	
	@echo "\n\033[92m--> Run database container\033[0m\n"
	docker network create magento2 || true
	docker-compose up -d magento2-mysql
	
	@echo "\n\033[92m--> Create magento project\033[0m\n"
	docker run ${build_args} composer --ansi create-project \
		--repository=https://repo.magento.com/ magento/project-community-edition ./
	
	@echo "\n\033[92m--> Install magento\033[0m\n"
	docker run ${build_args} bash -c 'bin/magento setup:install \
		--base-url=$${BASE_URL} \
		--db-host=$${DB_HOST} \
		--db-name=$${DB_NAME} \
		--db-user=$${DB_USER} \
		--db-password=$${DB_PASSWORD} \
		--admin-firstname=$${ADMIN_FIRSTNAME} \
		--admin-lastname=$${ADMIN_LASTNAME} \
		--admin-email=$${ADMIN_EMAIL} \
		--admin-user=$${ADMIN_USER} \
		--admin-password=$${ADMIN_PASSWORD} \
		--language=$${LANGUAGE} \
		--currency=$${CURRENCY} \
		--timezone=$${TIME_ZONE} \
		--use-rewrites=$${USE_REWRITES}'

	@echo "\n\033[92m--> Build nginx container\033[0m\n"
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

destroy:
	docker-compose down -v
	docker-compose rm -f -v
	docker network rm magento2 &>/dev/null || true
	docker-compose images -q | xargs docker rmi
	rm -rf ./db-data || true
	rm -rf ./magento2 || true
