# Протоколы сети интернет

### Цели:
- ##### Настроить DHCP в офисе Москва
- ##### Настроить синхронизацию времени в офисе Москва
- ##### Настроить NAT в офисе Москва, C.-Перетбруг и Чокурдах

### Описание/Пошаговая инструкция выполнения домашнего задания:
- ##### Настройте NAT(PAT) на R14 и R15. Трансляция должна осуществляться в адрес автономной системы AS1001.
- ##### Настройте NAT(PAT) на R18. Трансляция должна осуществляться в пул из 5 адресов автономной системы AS2042.
- ##### Настройте статический NAT для R20.
- ##### Настройте NAT так, чтобы R19 был доступен с любого узла для удаленного управления.
- ##### * Настройте статический NAT(PAT) для офиса Чокурдах.
- ##### Настроите для IPv4 DHCP сервер в офисе Москва на маршрутизаторах R12 и R13. VPC1 и VPC7 должны получать сетевые настройки по DHCP.
- ##### Настройте NTP сервер на R12 и R13. Все устройства в офисе Москва должны синхронизировать время с R12 и R13.

Экспорт лабораторной работы из EVE-NG:

- [Protocols.zip](export_zip/lab11_BGP_Filter.zip)

- ##### Настройте NAT(PAT) на R14 и R15. Трансляция должна осуществляться в адрес автономной системы AS1001.
Настройка на R14 и R15:
```cfg
access-list 78 permit 172.16.254.0 0.0.0.15
access-list 78 permit 192.168.10.0 0.0.1.255

ip nat inside source list 78 interface Ethernet0/2 overload

interface Ethernet0/0
  ip nat inside

interface Ethernet0/1
  ip nat inside

interface Ethernet0/2
 ip nat outside

!
interface Ethernet1/0
 ip nat inside
```


```cfg
MSK-VPC1> ping 192.168.21.10

84 bytes from 192.168.21.10 icmp_seq=1 ttl=58 time=2.434 ms
84 bytes from 192.168.21.10 icmp_seq=2 ttl=58 time=2.521 ms
84 bytes from 192.168.21.10 icmp_seq=3 ttl=58 time=3.206 ms
84 bytes from 192.168.21.10 icmp_seq=4 ttl=58 time=2.950 ms
84 bytes from 192.168.21.10 icmp_seq=5 ttl=58 time=2.756 ms

MSK-SW5# ping 192.168.21.10
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 192.168.21.10, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 2/2/3 ms

MSK-R15(config)#do sh ip nat translations
Pro Inside global      Inside local       Outside local      Outside global
icmp 10.0.254.19:40    172.16.254.5:40    192.168.21.10:40   192.168.21.10:40
icmp 10.0.254.19:41759 192.168.10.10:41759 192.168.21.10:41759 192.168.21.10:41759
icmp 10.0.254.19:42015 192.168.10.10:42015 192.168.21.10:42015 192.168.21.10:42015
icmp 10.0.254.19:42271 192.168.10.10:42271 192.168.21.10:42271 192.168.21.10:42271
icmp 10.0.254.19:42527 192.168.10.10:42527 192.168.21.10:42527 192.168.21.10:42527
icmp 10.0.254.19:42783 192.168.10.10:42783 192.168.21.10:42783 192.168.21.10:42783
```

![Скриншот 1](images/image1.png)

- ##### Настройте NAT(PAT) на R18. Трансляция должна осуществляться в пул из 5 адресов автономной системы AS2042.

Для реализации задачи пришлось измененить транспортных сетей между AS2042 и AS520, а также между сетями AS1001, AS101, AS301 т.к. ранее они были /31. Изменения отражены в [файле](export_zip/IP-plan.xlsx).

Настройка на R18:
```cfg
interface Ethernet0/0
 ip address 10.0.254.70 255.255.255.254
 ip nat inside
interface Ethernet0/1
 ip address 10.0.254.72 255.255.255.254
 ip nat inside

interface Ethernet0/2
 ip nat outside

interface Ethernet0/3
 ip nat outside

route-map TRD-R26 permit 10
 match ip address 78
 match interface Ethernet0/3
!
route-map TRD-R24 permit 10
 match ip address 78
 match interface Ethernet0/2

ip nat pool SPB-TRD24 10.78.254.11 10.78.254.15 prefix-length 27
ip nat pool SPB-TRD26 10.78.254.41 10.78.254.45 prefix-length 27
ip nat inside source route-map TRD-R24 pool SPB-TRD24
ip nat inside source route-map TRD-R26 pool SPB-TRD26
```

Проверка:
```cfg

SPB-VPC8> ping 192.168.30.10

84 bytes from 192.168.30.10 icmp_seq=1 ttl=59 time=2.093 ms
84 bytes from 192.168.30.10 icmp_seq=2 ttl=59 time=2.245 ms
84 bytes from 192.168.30.10 icmp_seq=3 ttl=59 time=2.530 ms
84 bytes from 192.168.30.10 icmp_seq=4 ttl=59 time=2.851 ms
84 bytes from 192.168.30.10 icmp_seq=5 ttl=59 time=2.413 ms

SPB-SW9#ping 192.168.30.10
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 192.168.30.10, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/1/2 ms

SPB-R18(config)#do sh ip nat trans
Pro Inside global      Inside local       Outside local      Outside global
icmp 10.78.254.43:5    172.16.254.21:5    192.168.30.10:5    192.168.30.10:5
icmp 10.78.254.43:6    172.16.254.21:6    192.168.30.10:6    192.168.30.10:6
icmp 10.78.254.43:7    172.16.254.21:7    192.168.30.10:7    192.168.30.10:7
icmp 10.78.254.42:17983 192.168.20.10:17983 192.168.30.10:17983 192.168.30.10:17983
icmp 10.78.254.42:18239 192.168.20.10:18239 192.168.30.10:18239 192.168.30.10:18239
icmp 10.78.254.42:18495 192.168.20.10:18495 192.168.30.10:18495 192.168.30.10:18495
icmp 10.78.254.42:18751 192.168.20.10:18751 192.168.30.10:18751 192.168.30.10:18751
icmp 10.78.254.42:19007 192.168.20.10:19007 192.168.30.10:19007 192.168.30.10:19007
icmp 10.78.254.42:19263 192.168.20.10:19263 192.168.30.10:19263 192.168.30.10:19263
icmp 10.78.254.42:19519 192.168.20.10:19519 192.168.30.10:19519 192.168.30.10:19519
icmp 10.78.254.42:19775 192.168.20.10:19775 192.168.30.10:19775 192.168.30.10:19775
icmp 10.78.254.42:20031 192.168.20.10:20031 192.168.30.10:20031 192.168.30.10:20031
icmp 10.78.254.42:20287 192.168.20.10:20287 192.168.30.10:20287 192.168.30.10:20287
icmp 10.78.254.42:20543 192.168.20.10:20543 192.168.30.10:20543 192.168.30.10:20543
icmp 10.78.254.42:20799 192.168.20.10:20799 192.168.30.10:20799 192.168.30.10:20799
icmp 10.78.254.42:21055 192.168.20.10:21055 192.168.30.10:21055 192.168.30.10:21055
```

![Скриншот 2](images/image2.png)


- ##### Настройте статический NAT для R20.
Настройка на R15:
```cfg
ip nat inside source static 10.0.254.11 10.77.254.40


```
Проверка доступности:
```cfg
SPB-VPC8> ping 10.77.254.40

84 bytes from 10.77.254.40 icmp_seq=1 ttl=250 time=2.370 ms
84 bytes from 10.77.254.40 icmp_seq=2 ttl=250 time=2.079 ms
84 bytes from 10.77.254.40 icmp_seq=3 ttl=250 time=2.771 ms
84 bytes from 10.77.254.40 icmp_seq=4 ttl=250 time=2.006 ms

CKD-R28#tracerout 10.77.254.40
Type escape sequence to abort.
Tracing the route to 10.77.254.40
VRF info: (vrf in name/id, vrf out name/id)
  1 10.0.254.140 0 msec 1 msec 0 msec
  2 10.0.254.52 1 msec 0 msec 1 msec
  3 10.0.254.43 0 msec 0 msec 1 msec
  4 10.77.254.1 2 msec 1 msec 1 msec
  5 10.0.254.15 1 msec *  11 msec
CKD-R28#ping 10.77.254.40
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 10.77.254.40, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/1/2 ms
```


- ##### Настройте NAT так, чтобы R19 был доступен с любого узла для удаленного управления.
Настройка на R14:
```cfg
ip nat inside source static 10.0.254.5 10.77.254.14

interface Ethernet0/3
 description "to R19.e0/0"
 ip nat inside
```
Проверка:
```cfg
MSK-R19#ping 192.168.30.10
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 192.168.30.10, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 1/1/3 ms

MSK-R14(config-router)#do sh ip nat tra
Pro Inside global      Inside local       Outside local      Outside global
udp 10.77.254.14:49212 10.0.254.5:49212   192.168.30.10:33492 192.168.30.10:33492
udp 10.77.254.14:49213 10.0.254.5:49213   192.168.30.10:33493 192.168.30.10:33493
udp 10.77.254.14:49214 10.0.254.5:49214   192.168.30.10:33494 192.168.30.10:33494
udp 10.77.254.14:49215 10.0.254.5:49215   192.168.30.10:33495 192.168.30.10:33495
udp 10.77.254.14:49216 10.0.254.5:49216   192.168.30.10:33496 192.168.30.10:33496
udp 10.77.254.14:49217 10.0.254.5:49217   192.168.30.10:33497 192.168.30.10:33497
udp 10.77.254.14:49218 10.0.254.5:49218   192.168.30.10:33498 192.168.30.10:33498
udp 10.77.254.14:49219 10.0.254.5:49219   192.168.30.10:33499 192.168.30.10:33499
udp 10.77.254.14:49220 10.0.254.5:49220   192.168.30.10:33500 192.168.30.10:33500
udp 10.77.254.14:49221 10.0.254.5:49221   192.168.30.10:33501 192.168.30.10:33501
udp 10.77.254.14:49222 10.0.254.5:49222   192.168.30.10:33502 192.168.30.10:33502
```
![Скриншот 3](images/image3.png)


- ##### Настроите для IPv4 DHCP сервер в офисе Москва на маршрутизаторах R12 и R13. VPC1 и VPC7 должны получать сетевые настройки по DHCP.
Настройка на R12:
```cfg
ip dhcp excluded-address 192.168.10.1
ip dhcp excluded-address 192.168.10.2
ip dhcp excluded-address 192.168.10.3
ip dhcp excluded-address 192.168.11.3
ip dhcp excluded-address 192.168.11.2
ip dhcp excluded-address 192.168.11.1
ip dhcp excluded-address 192.168.11.129 192.168.11.254
ip dhcp excluded-address 192.168.10.129 192.168.10.254
!
ip dhcp pool vlan10
 network 192.168.10.0 255.255.255.0
 default-router 192.168.10.1
 domain-name otus.lab.com
!
ip dhcp pool vlan11
 network 192.168.11.0 255.255.255.0
 default-router 192.168.11.1
 domain-name otus.lab.com
```

Настройка на R13:
```cfg
ip dhcp excluded-address 192.168.10.1
ip dhcp excluded-address 192.168.10.2
ip dhcp excluded-address 192.168.10.3
ip dhcp excluded-address 192.168.11.3
ip dhcp excluded-address 192.168.11.2
ip dhcp excluded-address 192.168.11.1
ip dhcp excluded-address 192.168.10.4 192.168.10.128
ip dhcp excluded-address 192.168.11.4 192.168.11.128
!
ip dhcp pool vlan10
 network 192.168.10.0 255.255.255.0
 default-router 192.168.10.1
 domain-name otus.lab.com
!
ip dhcp pool vlan11
 network 192.168.11.0 255.255.255.0
 default-router 192.168.11.1
 domain-name otus.lab.com
```

Проверка:
```cfg
MSK-VPC1> ip dhcp
DDORA IP 192.168.10.129/24 GW 192.168.10.1

MSK-VPC7> ip dhcp
DDORA IP 192.168.11.4/24 GW 192.168.11.1
```

- ##### Настройте NTP сервер на R12 и R13. Все устройства в офисе Москва должны синхронизировать время с R12 и R13.
Настройка на R12 и R13:
```cfg
ntp master 1
ntp update-calendar

interface Ethernet0/0.10
 ntp broadcast

interface Ethernet0/0.11
 ntp broadcast

interface Ethernet0/1
 no ip address

interface Ethernet0/1.55
 ntp broadcast

interface Ethernet0/2
 ntp broadcast
 
interface Ethernet0/3
 ntp broadcast
 
```
Настройка клиентов:
```cfg
ntp server 172.16.255.12
ntp server 172.16.255.13
```

Проверка:
```cfg
MSK-R19(config)#do sh ntp stat
Clock is synchronized, stratum 2, reference is 172.16.255.12
nominal freq is 250.0000 Hz, actual freq is 250.0000 Hz, precision is 2**10
ntp uptime is 3200 (1/100 of seconds), resolution is 4000
reference time is EAF2F5C9.1E76C908 (16:59:37.119 MSK Thu Nov 28 2024)
clock offset is 0.5000 msec, root delay is 1.00 msec
root dispersion is 193.34 msec, peer dispersion is 189.44 msec
loopfilter state is 'CTRL' (Normal Controlled Loop), drift is 0.000000000 s/s
system poll interval is 64, last update was 21 sec ago.


MSK-R14(config)#do sh ntp status
Clock is synchronized, stratum 2, reference is 172.16.255.12
nominal freq is 250.0000 Hz, actual freq is 250.0000 Hz, precision is 2**10
ntp uptime is 13600 (1/100 of seconds), resolution is 4000
reference time is EAF2F5F4.3B645AC0 (17:00:20.232 MSK Thu Nov 28 2024)
clock offset is 0.0000 msec, root delay is 0.00 msec
root dispersion is 69.08 msec, peer dispersion is 64.87 msec
loopfilter state is 'CTRL' (Normal Controlled Loop), drift is 0.000000000 s/s
system poll interval is 128, last update was 69 sec ago.
```



### Конфиги устройств:
- [R14](R14)
- [R15](R15)
- [R12](R12)
- [R13](R13)
- [R18](R18)
