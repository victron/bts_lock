# bts_lock
---
## Lock multipoint interfaces on cisco devices

заходим по ssh на
OSS 
```
$ ssh-add
Enter passphrase for /home/nsnras/.ssh/id_rsa:
```
вводишь 
если все ок
```
Identity added: /home/nsnras/.ssh/id_rsa (/home/nsnras/.ssh/id_rsa)
```
соответствия имен хостов и адресов в ~/.ssh/conf
по идее уже все туда добавил, если будет ошибка скажи - добавлю
```
./bts_inventory.sh
```
стоит запускать для обнавления базы (.db) BTS

####example
```
./bts_lock1.sh <BTS_name>
```
передергиваешь одну базуху
в последней версии добавил пинг, но оставил предыдущую
./bts_lock1.sh.back

запустить списком
```
cat bts.txt | ./bts_lock1.sh
```
отдельные логи пишутся о результате пингов
если вдруг нужен весь вывод sdtout 
```
cat bts.txt | ./bts_lock1.sh > smth.log
```

##### short instruction for vim
vi bts_T.txt
жмем i
внизу появляется надпись insert
жма правая кнопка мыши
жма Esc
жма : (Shift ;)
жма x
жма ентер

для нового списка проще удалить старый
rm bts_T.txt
и создать новый

узнать где находится базуха
```
$ grep <BTS_name> ./*.db
./<..>5.db:Mu216                          down           down     L3 link to <BTS_name>
./<..>6.db:Mu216                          down           down     L3 link to <BTS_name>
```
