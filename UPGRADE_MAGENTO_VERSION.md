## Magento2 version upgrading guide

1. [Check requirements](https://devdocs.magento.com/guides/v2.4/install-gde/system-requirements.html)

2. Change `MAGENTO_VERSION` variable in `env/*.env` files to new version

3. Review `php-fpm/Dockerfile` and make sure that all requirements are met

4. Review `docker-compose.yml` and make sure that all requirements are met

5. Run `make build` and wait until build complete

6. Copy `magento2/nginx.conf.sample` content to `nginx/conf.d/magento2-includes.config`

7. Run `docker-compose build && docker-compose up -d`
