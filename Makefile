# import environment variables
env ?= local
env_file := env/$(env).build.env
build_args := -i --rm --env-file ${env_file} -v $${PWD}/magento2:/var/www/magento2 --network magento2 magento2php:latest

all: build up

build:
	@[[ -f ./php-fpm/auth.json ]] || { echo '\nCreate magento2 repo auth file first ./php-fpm/auth.json\n'; exit 1; }
	@[[ -d ./magento2 ]] && { echo '\n./magento2 directory already exist\n'; exit 1; } || true
	
	@echo "\n\033[1;92m--> Build php-fpm container\033[0m\n"
	docker build --no-cache -t magento2php:latest ./php-fpm
	
	@echo "\n\033[1;92m--> Run database container\033[0m\n"
	docker network create magento2 || true
	docker-compose up -d magento2-mysql
	
	@echo "\n\033[1;92m--> Run elasticsearch container\033[0m\n"
	docker-compose up -d magento2-elasticsearch

	@echo "\n\033[1;92m--> Create magento2 project\033[0m\n"
	docker run ${build_args} composer --ansi create-project \
		--repository=https://repo.magento.com/ magento/project-community-edition=$${MAGENTO_VERSION} ./

	@echo "\n\033[1;92m--> Copy composer auth.json to the project composer home directory\033[0m\n"
	docker run ${build_args} bash  -c 'mkdir -p /var/www/magento2/var/composer_home \
		&& cp /root/composer_home/auth.json /var/www/magento2/var/composer_home/auth.json'

	@echo "\n\033[1;92m--> Install magento2\033[0m\n"
	docker run ${build_args} bash -c 'bin/magento setup:install \
		--base-url=$${BASE_URL} \
		--db-host=$${DB_HOST} \
		--db-name=$${DB_NAME} \
		--db-user=$${DB_USER} \
		--db-password=$${DB_PASSWORD} \
		--search-engine=$${ES_ENGINE} \
		--elasticsearch-host=$${ES_HOST} \
		--admin-firstname=$${ADMIN_FIRSTNAME} \
		--admin-lastname=$${ADMIN_LASTNAME} \
		--admin-email=$${ADMIN_EMAIL} \
		--admin-user=$${ADMIN_USER} \
		--admin-password=$${ADMIN_PASSWORD} \
		--language=$${LANGUAGE} \
		--currency=$${CURRENCY} \
		--timezone=$${TIME_ZONE} \
		--use-rewrites=$${USE_REWRITES}' | tee ./build.log
	
	@echo "\n\033[1;92m--> Set timezone to UTC in DB\033[0m\n"
	docker-compose exec magento2-mysql bash -c \
		'mysql -uroot -p$${MYSQL_ROOT_PASSWORD} -D $${MYSQL_DATABASE} -e \
		'"'"'UPDATE `core_config_data` SET value = "UTC" WHERE `path` = "general/locale/timezone";'"'"''

	@echo "\n\033[1;92m--> Setup magento2 cron jobs\033[0m\n"
	docker run -v $${PWD}/crontabs:/var/spool/cron/crontabs ${build_args} bash -c 'bin/magento cron:install || true'

	@echo "\n\033[1;92m--> Build nginx container\033[0m\n"
	docker-compose build

	@echo "\n\033[1;92m--> Magento admin URI\033[0m\n"
	@cat build.log | grep "Magento Admin URI:" | cut -d" " -f2- | tee ./admin_uri.log
	@rm -f ./build.log

up:
	@echo "\n\033[1;92m--> Up all docker containers\033[0m\n"
	docker-compose up -d

down:
	@echo "\n\033[1;92m--> Down all docker containers\033[0m\n"
	docker-compose down

ps:
	@echo && docker-compose ps && echo

destroy:
	@echo "\n\033[1;91mWARNING: All created docker resources and volumes will be destroyed!\033[0m\n"
	@echo "Press Ctrl+C to cancel\n"
	@sleep 10
	docker-compose down -v
	docker-compose rm -f -v
	docker network rm magento2 &>/dev/null || true
	docker-compose images -q | xargs docker rmi
	rm -rf ./db-data || true
	rm -rf ./es-data || true
	rm -rf ./magento2 || true
	rm -rf ./crontabs || true
	rm -f ./admin_uri.log || true

login:
	docker-compose exec magento2-php bash

mysql:
	docker-compose exec magento2-mysql bash -c 'mysql -uroot -p$${MYSQL_ROOT_PASSWORD} --database $${MYSQL_DATABASE}'

sampledata:
	@echo "\n\033[1;92m--> Deploying sample data. It will take a few minutes.\033[0m\n"
	docker-compose up -d
	docker run ${build_args} bash -c '\
		bin/magento deploy:mode:set developer \
		&& bin/magento sampledata:deploy \
		&& bin/magento setup:upgrade \
		&& bin/magento deploy:mode:set default'
	@echo "\n\033[1;92m--> Sample data deployment completed.\033[0m\n"
