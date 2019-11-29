## Magento2 docker

### Build and run

Copy `php-fpm/auth.json.dist` to `php-fpm/auth.json` and configure magento repo credentials. How to create magento credentials look at [this magento doc page](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/connect-auth.html).

Run `make build` for building magento2 docker containers and source directory. `./db-data` and `./magento2` directories will be created. The first one is mysql container data directory volume. The second one is magento2 php-fpm container src volume directory. 

**NOTE**: At the end of this task you will get **admin page login endpoint**. Save it!

By default `./env/local.build.env` file will be used. You can create any buld file for example `./env/dev.build.env` and run `make build env=dev`. Database credentials in a `*.buidl.env` file and in the `docker-compose.yml` file must be the same.

Run `make up` to run all of the containers in the `docker-compose.yml`

**NOTE**: You can just run `make` to build and run magento2.

### Deploy sample data

Run `make sampledata` to deploy sample data. Run it only after build and 

### Stop and destroy

1. Run `make down` to stop all of the containers.

2. Run `make destroy` to remove all generated data - docker containers, volumes, networks. `./db-data` and `./magento2` directories will be removed too.

### Run magento commands

Run `make login` to login inside magento2-php container. Now you can run any magento commands `bin/magento ...`

### Aditional commands

1. Run `make mysql` to open mysql console on magento DB.

2. Run `make down` to stop and `make up` to start all builded containers. Short analog of `docker-compose up/down`

3. Run `make ps` to show all the containers status. Short analog of `docker-compose ps`.