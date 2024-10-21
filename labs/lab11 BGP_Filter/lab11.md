# BGP Фильтрация

### Цели:
- ##### Настроить фильтрацию для офисе Москва
- ##### Настроить фильтрацию для офисе С.-Петербург

### Описание/Пошаговая инструкция выполнения домашнего задания:
- ##### Настроить фильтрацию в офисе Москва так, чтобы не появилось транзитного трафика(As-path).
- ##### Настроить фильтрацию в офисе С.-Петербург так, чтобы не появилось транзитного трафика(Prefix-list).
- ##### Настроить провайдера Киторн так, чтобы в офис Москва отдавался только маршрут по умолчанию.
- ##### Настроить провайдера Ламас так, чтобы в офис Москва отдавался только маршрут по умолчанию и префикс офиса С.-Петербург.
- ##### Все сети в лабораторной работе должны иметь IP связность.


### Схема лабораторной работы:
![Схема лабораторной работы](images/scheme.png)

Экспорт лабораторной работы из EVE-NG:

- [BGP_Filter.zip](export_zip/lab11_BGP_Filter.zip)

- ##### Настроить фильтрацию в офисе Москва так, чтобы не появилось транзитного трафика(As-path).
Настройки MSK-R14 
```cfg
router bgp 1001
 bgp router-id 172.16.255.14
 bgp log-neighbor-changes
 network 10.0.254.14 mask 255.255.255.254
 network 10.0.254.16 mask 255.255.255.254
 network 172.16.255.14 mask 255.255.255.255
 redistribute ospf 1
 neighbor 10.0.254.16 remote-as 101
 neighbor 10.0.254.16 soft-reconfiguration inbound
 neighbor 10.0.254.16 filter-list 1 out
 neighbor 172.16.255.15 remote-as 1001
 neighbor 172.16.255.15 update-source Loopback0
!
ip as-path access-list 1 permit ^$
```
Настройки MSK-R15:
```cfg
router bgp 1001
 bgp router-id 172.16.255.15
 bgp log-neighbor-changes
 network 10.0.254.14 mask 255.255.255.254
 network 10.0.254.18 mask 255.255.255.254
 network 172.16.255.15 mask 255.255.255.255
 redistribute ospf 1
 neighbor 10.0.254.18 remote-as 301
 neighbor 10.0.254.18 route-map AS301-IN in
 neighbor 10.0.254.18 filter-list 1 out
 neighbor 172.16.255.14 remote-as 1001
 neighbor 172.16.255.14 update-source Loopback0
!
ip as-path access-list 1 permit ^$
```

- ##### Настроить фильтрацию в офисе С.-Петербург так, чтобы не появилось транзитного трафика(Prefix-list).
Настройки на R18:
```cfg
router bgp 2042
 bgp log-neighbor-changes
 bgp bestpath as-path multipath-relax
 network 10.0.254.66 mask 255.255.255.254
 network 10.0.254.68 mask 255.255.255.254
 network 172.16.255.18 mask 255.255.255.255
 redistribute eigrp 78
 neighbor 10.0.254.66 remote-as 520
 neighbor 10.0.254.66 prefix-list NO-TRANSIT out
 neighbor 10.0.254.68 remote-as 520
 neighbor 10.0.254.68 prefix-list NO-TRANSIT out
 maximum-paths 2
!
ip prefix-list NO-TRANSIT seq 10 permit 10.0.254.64/28
ip prefix-list NO-TRANSIT seq 20 permit 192.168.20.0/23
ip prefix-list NO-TRANSIT seq 30 permit 172.16.254.16/28
ip prefix-list NO-TRANSIT seq 41 permit 172.16.255.18/32
ip prefix-list NO-TRANSIT seq 42 permit 172.16.255.16/32
ip prefix-list NO-TRANSIT seq 43 permit 172.16.255.17/32
ip prefix-list NO-TRANSIT seq 44 permit 172.16.255.32/32
ip prefix-list NO-TRANSIT seq 50 deny 0.0.0.0/0 le 32

```

- ##### Настроить провайдера Киторн так, чтобы в офис Москва отдавался только маршрут по умолчанию.
Настройка на KTN-R22:
```cfg
router bgp 101
 bgp router-id 172.16.255.22
 bgp log-neighbor-changes
 network 172.16.255.22 mask 255.255.255.255
 neighbor 10.0.254.17 remote-as 1001
 neighbor 10.0.254.17 default-originate
 neighbor 10.0.254.17 prefix-list DEFAULT-TO-AS1001 out
 neighbor 10.0.254.20 remote-as 301
 neighbor 10.0.254.42 remote-as 520
!
ip prefix-list DEFAULT-TO-AS1001 seq 5 permit 0.0.0.0/0
```
Результат:
```cfg
MSK-R14#sh ip bgp neighbors 10.0.254.16 received-routes
BGP table version is 211, local router ID is 172.16.255.14
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *   0.0.0.0          10.0.254.16                            0 101 i

Total number of prefixes 1
```

- ##### Настроить провайдера Ламас так, чтобы в офис Москва отдавался только маршрут по умолчанию и префикс офиса С.-Петербург.
Настройка на LMS-R21
```cfg 
router bgp 301
 bgp router-id 172.16.255.21
 bgp log-neighbor-changes
 network 172.16.255.21 mask 255.255.255.255
 neighbor 10.0.254.19 remote-as 1001
 neighbor 10.0.254.19 default-originate
 neighbor 10.0.254.19 filter-list 1 out
 neighbor 10.0.254.21 remote-as 101
 neighbor 10.0.254.40 remote-as 520
!
ip as-path access-list 1 permit _2042$
```
Результат на MSK-R15:
```cfg
MSK-R15#sh ip bgp neighbors 10.0.254.18 received-routes
BGP table version is 192, local router ID is 172.16.255.15
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *   0.0.0.0          10.0.254.18                            0 301 i
 *   172.16.254.16/28 10.0.254.18                            0 301 520 2042 ?
 *   172.16.255.16/32 10.0.254.18                            0 301 520 2042 ?
 *   172.16.255.17/32 10.0.254.18                            0 301 520 2042 ?
 *   172.16.255.18/32 10.0.254.18                            0 301 520 2042 i
 *   172.16.255.32/32 10.0.254.18                            0 301 520 2042 ?
 *   192.168.20.0/23  10.0.254.18                            0 301 520 2042 ?

Total number of prefixes 7
```

### Конфиги устройств:
- [R14](R14)
- [R15](R15)
- [R18](R18)
- [R21](R21)
- [R22](R22)
