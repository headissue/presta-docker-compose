# Prestashop dev setup
run
```shell
docker-compose up
```
open http://localhost:8881, you should see an example shop  
open http://localhost:8881/admin074glnyfjklwzhcgnrk, you should be able to log in with `demo@prestashop.com` - `prestashop_demo`  
connect to jdbc:mariadb://localhost:3308 with user `root` and `rootpw` and you should see a shop1 database

make volume writeable to dev
```shell
chmod -R a+w ./shop1_data
```

# get the NetBeans IDE
new project from existing sources in `shop1_data/html`
