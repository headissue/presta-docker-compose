# Prestashop dev setup
run
```shell
docker-compose up
```
open [index](http://localhost:8881), you should see an example shop  
open [admin](http://localhost:8881/admdev), you should be able to log in with `demo@prestashop.com` - `prestashop_demo`  

## Interact with the database

Via CLI in the database docker container:

````
docker exec prestashop-db mysqladmin --protocol=TCP -P 3306 -p -u root -prootpw status
````

Or via local mysql client programs:

````
mysqladmin --protocol=TCP -P 3308 -p -u root -prootpw status
````

Via Java based IDE: connect to `jdbc:mariadb://localhost:3308` with user `root` and `rootpw` and you should see a shop1 database


make volume writeable to dev
```shell
chmod -R a+w ./shop1_data
```

# get the NetBeans IDE
new project from existing sources in `shop1_data/html`
