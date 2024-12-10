# Протоколы сети интернет

### Цели:
- ##### Настроить GRE поверх IPSec между офисами Москва и С.-Петербург
- ##### Настроить DMVPN поверх IPSec между офисами Москва и Чокурдах, Лабытнанги

### Описание/Пошаговая инструкция выполнения домашнего задания:
- ##### Настроите GRE поверх IPSec между офисами Москва и С.-Петербург
- ##### Настроите DMVPN поверх IPSec между Москва и Чокурдах, Лабытнанги
- ##### Для IPSec использовать CA и сертификаты


Экспорт лабораторной работы из EVE-NG:

- [IPsec.zip](export_zip/IPsec.zip)

- ##### Настроите GRE поверх IPSec между офисами Москва и С.-Петербург
Настройка на R15 туннеля между офисами СПБ и МСК:
```cfg
crypto ikev2 proposal IKEv2PROPOSAL-SPB
 encryption aes-cbc-128
 integrity md5
 group 2
!
crypto ikev2 policy IKEv2POLICY-SPB
 proposal IKEv2PROPOSAL-SPB
!
crypto ikev2 keyring IKEv2KEY-SPB
 peer SPB-R18
  address 10.77.78.1
  pre-shared-key OTUS
 !
!
!
crypto ikev2 profile IKEv2PROFILE-SPB
 match identity remote address 10.78.254.1 255.255.255.255
 authentication remote pre-share
 authentication local pre-share
 keyring local IKEv2KEY-SPB
!
!
!
crypto ipsec transform-set IPSECTS-SPB esp-aes esp-md5-hmac
 mode transport
!
crypto ipsec profile IPSECPROFILE-SPB
 set transform-set IPSECTS-SPB
 set ikev2-profile IKEv2PROFILE-SPB

interface Tunnel100
 description "GRE-to-SPB"
 ip address 10.77.78.0 255.255.255.254
 ip mtu 1400
 ip tcp adjust-mss 1360
 tunnel source 10.77.254.33
 tunnel destination 10.78.254.1
 tunnel protection ipsec profile IPSECPROFILE-SPB
```

Настройка на R18:
```cfg
crypto ikev2 proposal IKEv2PROPOSAL-MSK
 encryption aes-cbc-128
 integrity md5
 group 2
!
crypto ikev2 policy IKEv2POLICY-MSK
 proposal IKEv2PROPOSAL-MSK
!
crypto ikev2 keyring IKEv2KEY-MSK
 peer SPB-R15
  address 10.77.78.0 255.255.255.0
  pre-shared-key OTUS
 !
!
crypto ikev2 profile IKEv2PROFILE-MSK
 match identity remote address 10.77.254.33 255.255.255.255
 authentication remote pre-share
 authentication local pre-share
 keyring local IKEv2KEY-MSK
!
crypto ipsec transform-set IPSECTS-MSK esp-aes esp-md5-hmac
 mode transport
!
crypto ipsec profile IPSECPROFILE-MSK
 set transform-set IPSECTS-MSK
 set ikev2-profile IKEv2PROFILE-MSK
!
interface Tunnel100
 description "GRE-to-MSK"
 ip address 10.77.78.1 255.255.255.254
 ip mtu 1400
 ip tcp adjust-mss 1360
 tunnel source 10.78.254.1
 tunnel destination 10.77.254.33
 tunnel protection ipsec profile IPSECPROFILE-MSK
```

Проверка:
```cfg
SPB-VPC8> ping 192.168.10.129

84 bytes from 192.168.10.129 icmp_seq=1 ttl=59 time=5.381 ms
84 bytes from 192.168.10.129 icmp_seq=2 ttl=59 time=3.594 ms
84 bytes from 192.168.10.129 icmp_seq=3 ttl=59 time=3.797 ms


MSK-VPC1> ping 192.168.20.10

84 bytes from 192.168.20.10 icmp_seq=1 ttl=60 time=4.881 ms
84 bytes from 192.168.20.10 icmp_seq=2 ttl=60 time=3.592 ms
84 bytes from 192.168.20.10 icmp_seq=3 ttl=60 time=3.733 ms
^C
MSK-VPC1>
```
IKE и IPSEC SA на маршрутизаторах:
```cfg
MSK-R15(config-ikev2-profile)#do sh crypto ikev2 sa
 IPv4 Crypto IKEv2  SA

Tunnel-id Local                 Remote                fvrf/ivrf            Status
1         10.77.254.33/500      10.78.254.1/500       none/none            READY
      Encr: AES-CBC, keysize: 128, PRF: MD5, Hash: MD596, DH Grp:2, Auth sign: PSK, Auth verify: PSK
      Life/Active Time: 86400/621 sec

 IPv6 Crypto IKEv2  SA

MSK-R15(config-ikev2-profile)#do sh crypto ipsec sa

interface: Tunnel100
    Crypto map tag: Tunnel100-head-0, local addr 10.77.254.33

   protected vrf: (none)
   local  ident (addr/mask/prot/port): (10.77.254.33/255.255.255.255/47/0)
   remote ident (addr/mask/prot/port): (10.78.254.1/255.255.255.255/47/0)
   current_peer 10.78.254.1 port 500
     PERMIT, flags={origin_is_acl,}
    #pkts encaps: 11, #pkts encrypt: 11, #pkts digest: 11
    #pkts decaps: 147, #pkts decrypt: 147, #pkts verify: 147
    #pkts compressed: 0, #pkts decompressed: 0
    #pkts not compressed: 0, #pkts compr. failed: 0
    #pkts not decompressed: 0, #pkts decompress failed: 0
    #send errors 0, #recv errors 0

     local crypto endpt.: 10.77.254.33, remote crypto endpt.: 10.78.254.1
     plaintext mtu 1458, path mtu 1500, ip mtu 1500, ip mtu idb Ethernet0/2
     current outbound spi: 0x3F5AF7A2(1062926242)
     PFS (Y/N): N, DH group: none

     inbound esp sas:
      spi: 0xFCA5F4BB(4238734523)
        transform: esp-aes esp-md5-hmac ,
        in use settings ={Transport, }
        conn id: 2, flow_id: SW:2, sibling_flags 80000000, crypto map: Tunnel100-head-0
        sa timing: remaining key lifetime (k/sec): (4263014/2972)
        IV size: 16 bytes
        replay detection support: Y
        Status: ACTIVE(ACTIVE)

     inbound ah sas:

     inbound pcp sas:

     outbound esp sas:
      spi: 0x3F5AF7A2(1062926242)
        transform: esp-aes esp-md5-hmac ,
        in use settings ={Transport, }
        conn id: 1, flow_id: SW:1, sibling_flags 80000000, crypto map: Tunnel100-head-0
        sa timing: remaining key lifetime (k/sec): (4263032/2972)
        IV size: 16 bytes
        replay detection support: Y
        Status: ACTIVE(ACTIVE)

     outbound ah sas:

     outbound pcp sas:
MSK-R15(config-ikev2-profile)#

SPB-R18(config-ikev2-profile)#do sh crypto ipsec sa

interface: Tunnel100
    Crypto map tag: Tunnel100-head-0, local addr 10.78.254.1

   protected vrf: (none)
   local  ident (addr/mask/prot/port): (10.78.254.1/255.255.255.255/47/0)
   remote ident (addr/mask/prot/port): (10.77.254.33/255.255.255.255/47/0)
   current_peer 10.77.254.33 port 500
     PERMIT, flags={origin_is_acl,}
    #pkts encaps: 159, #pkts encrypt: 159, #pkts digest: 159
    #pkts decaps: 11, #pkts decrypt: 11, #pkts verify: 11
    #pkts compressed: 0, #pkts decompressed: 0
    #pkts not compressed: 0, #pkts compr. failed: 0
    #pkts not decompressed: 0, #pkts decompress failed: 0
    #send errors 0, #recv errors 0

     local crypto endpt.: 10.78.254.1, remote crypto endpt.: 10.77.254.33
     plaintext mtu 1458, path mtu 1500, ip mtu 1500, ip mtu idb Ethernet0/2
     current outbound spi: 0xFCA5F4BB(4238734523)
     PFS (Y/N): N, DH group: none

     inbound esp sas:
      spi: 0x3F5AF7A2(1062926242)
        transform: esp-aes esp-md5-hmac ,
        in use settings ={Transport, }
        conn id: 3, flow_id: SW:3, sibling_flags 80000000, crypto map: Tunnel100-head-0
        sa timing: remaining key lifetime (k/sec): (4358379/2942)
        IV size: 16 bytes
        replay detection support: Y
        Status: ACTIVE(ACTIVE)

     inbound ah sas:

     inbound pcp sas:

     outbound esp sas:
      spi: 0xFCA5F4BB(4238734523)
        transform: esp-aes esp-md5-hmac ,
        in use settings ={Transport, }
        conn id: 4, flow_id: SW:4, sibling_flags 80000000, crypto map: Tunnel100-head-0
        sa timing: remaining key lifetime (k/sec): (4358361/2942)
        IV size: 16 bytes
        replay detection support: Y
        Status: ACTIVE(ACTIVE)

     outbound ah sas:

     outbound pcp sas:
```

![Скриншот 1](images/image1.png)

- ##### Настроите DMVPN поверх IPSec между Москва и Чокурдах, Лабытнанги
Настройка IPSec для DMVPN  на роутерах MSK-R15, CKD-R28 и LBT-27:
```cfg
crypto ikev2 proposal IKEv2PROPOSAL-DMVPN
 encryption aes-cbc-128
 integrity md5
 group 2

crypto ikev2 policy IKEv2POLICY-DMVPN
 proposal IKEv2PROPOSAL-DMVPN

crypto ikev2 keyring IKEv2-DMVPN
 peer dmvpn-node
  address 0.0.0.0 0.0.0.0
  pre-shared-key OTUS-DMVPN
!
crypto ikev2 profile IKEv2PROFILE-DMVPN
 keyring local IKEv2-DMVPN
 authentication local pre-share
 authentication remote pre-share
 match address local 0.0.0.0
 match identity remote address 0.0.0.0 0.0.0.0
!
 
crypto ipsec transform-set IPSECTS-DMVPN esp-aes esp-md5-hmac
  mode transport

crypto ipsec profile IPSECPROFILE-DMVPN
  set transform-set IPSECTS-DMVPN
  set ikev2-profile IKEv2PROFILE-DMVPN

interface Tunnel150
 tunnel protection ipsec profile IPSECPROFILE-DMVPN
```
Проверка:
```cfg
MSK-R15(config-ikev2-profile)#do sh ip nhrp
10.77.0.2/32 via 10.77.0.2
   Tunnel150 created 00:02:14, expire 00:08:27
   Type: dynamic, Flags: registered nhop
   NBMA address: 10.0.254.89
10.77.0.3/32 via 10.77.0.3
   Tunnel150 created 00:02:07, expire 00:08:05
   Type: dynamic, Flags: registered nhop
   NBMA address: 10.0.254.141
MSK-R15(config-ikev2-profile)#do sh dmvpn
Legend: Attrb --> S - Static, D - Dynamic, I - Incomplete
        N - NATed, L - Local, X - No Socket
        T1 - Route Installed, T2 - Nexthop-override
        C - CTS Capable, I2 - Temporary
        # Ent --> Number of NHRP entries with same NBMA peer
        NHS Status: E --> Expecting Replies, R --> Responding, W --> Waiting
        UpDn Time --> Up or Down Time for a Tunnel
==========================================================================

Interface: Tunnel150, IPv4 NHRP Details
Type:Hub, NHRP Peers:2,

 # Ent  Peer NBMA Addr Peer Tunnel Add State  UpDn Tm Attrb
 ----- --------------- --------------- ----- -------- -----
     1 10.0.254.89           10.77.0.2    UP 00:02:18     D
     1 10.0.254.141          10.77.0.3    UP 00:02:11     D

MSK-R15(config-ikev2-profile)#do sh  crypto ikev2 sa
 IPv4 Crypto IKEv2  SA

Tunnel-id Local                 Remote                fvrf/ivrf            Status
3         10.77.254.33/500      10.0.254.141/500      none/none            READY
      Encr: AES-CBC, keysize: 128, PRF: MD5, Hash: MD596, DH Grp:2, Auth sign: PSK, Auth verify: PSK
      Life/Active Time: 86400/144 sec

Tunnel-id Local                 Remote                fvrf/ivrf            Status
1         10.77.254.33/500      10.78.254.1/500       none/none            READY
      Encr: AES-CBC, keysize: 128, PRF: MD5, Hash: MD596, DH Grp:2, Auth sign: PSK, Auth verify: PSK
      Life/Active Time: 86400/2582 sec

Tunnel-id Local                 Remote                fvrf/ivrf            Status
2         10.77.254.33/500      10.0.254.89/500       none/none            READY
      Encr: AES-CBC, keysize: 128, PRF: MD5, Hash: MD596, DH Grp:2, Auth sign: PSK, Auth verify: PSK
      Life/Active Time: 86400/151 sec

 IPv6 Crypto IKEv2  SA

MSK-R15(config-ikev2-profile)#do sh  crypto ipsec sa
interface: Tunnel150
    Crypto map tag: Tunnel150-head-0, local addr 10.77.254.33

   protected vrf: (none)
   local  ident (addr/mask/prot/port): (10.77.254.33/255.255.255.255/47/0)
   remote ident (addr/mask/prot/port): (10.0.254.141/255.255.255.255/47/0)
   current_peer 10.0.254.141 port 500
     PERMIT, flags={origin_is_acl,}
    #pkts encaps: 62, #pkts encrypt: 62, #pkts digest: 62
    #pkts decaps: 64, #pkts decrypt: 64, #pkts verify: 64
    #pkts compressed: 0, #pkts decompressed: 0
    #pkts not compressed: 0, #pkts compr. failed: 0
    #pkts not decompressed: 0, #pkts decompress failed: 0
    #send errors 0, #recv errors 0

     local crypto endpt.: 10.77.254.33, remote crypto endpt.: 10.0.254.141
     plaintext mtu 1458, path mtu 1500, ip mtu 1500, ip mtu idb Ethernet0/2
     current outbound spi: 0x5F4C40B3(1598832819)
     PFS (Y/N): N, DH group: none

     inbound esp sas:
      spi: 0x143C7AC2(339507906)
        transform: esp-aes esp-md5-hmac ,
        in use settings ={Transport, }
        conn id: 5, flow_id: SW:5, sibling_flags 80000000, crypto map: Tunnel150-head-0
        sa timing: remaining key lifetime (k/sec): (4238587/3445)
        IV size: 16 bytes
        replay detection support: Y
        Status: ACTIVE(ACTIVE)

     inbound ah sas:

     inbound pcp sas:

     outbound esp sas:
      spi: 0x5F4C40B3(1598832819)
        transform: esp-aes esp-md5-hmac ,
        in use settings ={Transport, }
        conn id: 6, flow_id: SW:6, sibling_flags 80000000, crypto map: Tunnel150-head-0
        sa timing: remaining key lifetime (k/sec): (4238587/3445)
        IV size: 16 bytes
        replay detection support: Y
        Status: ACTIVE(ACTIVE)

     outbound ah sas:

     outbound pcp sas:

   protected vrf: (none)
   local  ident (addr/mask/prot/port): (10.77.254.33/255.255.255.255/47/0)
   remote ident (addr/mask/prot/port): (10.0.254.89/255.255.255.255/47/0)
   current_peer 10.0.254.89 port 500
     PERMIT, flags={origin_is_acl,}
    #pkts encaps: 51, #pkts encrypt: 51, #pkts digest: 51
    #pkts decaps: 48, #pkts decrypt: 48, #pkts verify: 48
    #pkts compressed: 0, #pkts decompressed: 0
    #pkts not compressed: 0, #pkts compr. failed: 0
    #pkts not decompressed: 0, #pkts decompress failed: 0
    #send errors 0, #recv errors 0

     local crypto endpt.: 10.77.254.33, remote crypto endpt.: 10.0.254.89
     plaintext mtu 1458, path mtu 1500, ip mtu 1500, ip mtu idb Ethernet0/2
     current outbound spi: 0x72AE893A(1924041018)
     PFS (Y/N): N, DH group: none

     inbound esp sas:
      spi: 0xE0C1E232(3770802738)
        transform: esp-aes esp-md5-hmac ,
        in use settings ={Transport, }
        conn id: 3, flow_id: SW:3, sibling_flags 80000000, crypto map: Tunnel150-head-0
        sa timing: remaining key lifetime (k/sec): (4362525/3438)
        IV size: 16 bytes
        replay detection support: Y
        Status: ACTIVE(ACTIVE)

     inbound ah sas:

     inbound pcp sas:

     outbound esp sas:
      spi: 0x72AE893A(1924041018)
        transform: esp-aes esp-md5-hmac ,
        in use settings ={Transport, }
        conn id: 4, flow_id: SW:4, sibling_flags 80000000, crypto map: Tunnel150-head-0
        sa timing: remaining key lifetime (k/sec): (4362525/3438)
        IV size: 16 bytes
        replay detection support: Y
        Status: ACTIVE(ACTIVE)

     outbound ah sas:

     outbound pcp sas:


MSK-R15(config-ikev2-profile)#
MSK-R15(config-ikev2-profile)#do sh ip ro eigrp
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route, H - NHRP, l - LISP
       a - application route
       + - replicated route, % - next hop override, p - overrides from PfR

Gateway of last resort is 10.77.254.62 to network 0.0.0.0

      172.16.0.0/16 is variably subnetted, 10 subnets, 3 masks
D        172.16.254.32/29 [90/26905600] via 10.77.0.3, 00:03:09, Tunnel150
D        172.16.255.27/32 [90/27008000] via 10.77.0.2, 00:03:09, Tunnel150
D        172.16.255.28/32 [90/27008000] via 10.77.0.3, 00:03:09, Tunnel150
D     192.168.30.0/24 [90/26905600] via 10.77.0.3, 00:03:09, Tunnel150
D     192.168.31.0/24 [90/26905600] via 10.77.0.3, 00:03:09, Tunnel150
```

![Скриншот 2](images/image2.png)

- ##### Для IPSec использовать CA и сертификаты
Инициализация CA  на R14:
```cfg
ip domain-name otus.ru 
ip http server
crypto key generate rsa general-keys label CA exportable modulus 2048
crypto pki server CA 
  no shut
```
Запросы на  сертификаты:
```cfg
crypto key generate rsa label VPN modulus 2048
crypto pki trustpoint VPN
  enrollment url http://10.77.254.1
  subject-name CN=CRD-R28,OU=VPN,O=Otus,C=RU 
  rsakeypair VPN
  revocation-check none

crypto pki authenticate VPN
crypto pki enroll VPN

crypto key generate rsa label VPN modulus 2048
crypto pki trustpoint VPN
  enrollment url http://10.77.254.1
  subject-name CN=LBT-R27,OU=VPN,O=Otus,C=RU 
  rsakeypair VPN
  revocation-check none

crypto pki authenticate VPN
crypto pki enroll VPN

crypto key generate rsa label VPN modulus 2048
crypto pki trustpoint VPN
  enrollment url http://10.77.254.1
  subject-name CN=MSK-R15,OU=VPN,O=Otus,C=RU 
  rsakeypair VPN
  revocation-check none

crypto pki authenticate VPN
crypto pki enroll VPN

crypto key generate rsa label VPN modulus 2048
crypto pki trustpoint VPN
  enrollment url http://10.77.254.1
  subject-name CN=SPB-R18,OU=VPN,O=Otus,C=RU 
  rsakeypair VPN
  revocation-check none
crypto pki authenticate VPN
crypto pki enroll VPN
```
Просмотр запросов:
```cfg
MSK-R14(cs-server)#do sho crypto pki server CA requests
Enrollment Request Database:

Subordinate CA certificate requests:
ReqID  State      Fingerprint                      SubjectName
--------------------------------------------------------------

RA certificate requests:
ReqID  State      Fingerprint                      SubjectName
--------------------------------------------------------------

Router certificates requests:
ReqID  State      Fingerprint                      SubjectName
--------------------------------------------------------------
3      pending    002436B085AFFFE332CA2FEA2FC50F66 hostname=MSK-R15.otus.local,cn=MSK-R15,ou=VPN,o=Otus,c=RU
2      pending    78104E2CFDD7D5233BDC2D2F1D19F95B hostname=LBT-R27.otus.local,cn=LBT-R27,ou=VPN,o=Otus,c=RU
1      pending    2A600727DA6AE564844A4C5B06CCD219 hostname=CKD-R28.otus.local,cn=CRD-R28,ou=VPN,o=Otus,c=RU

```
Выпуск сертификатов:
```cfg
MSK-R14(cs-server)#do crypto pki server CA grant 1
MSK-R14(cs-server)#do crypto pki server CA grant 2
MSK-R14(cs-server)#do crypto pki server CA grant 3
```
Просмотр  сертификатов:
```cfg
MSK-R15(config)#do  sh crypto pki certificates
Certificate
  Status: Available
  Certificate Serial Number (hex): 04
  Certificate Usage: General Purpose
  Issuer:
    cn=CA
  Subject:
    Name: MSK-R15.otus.local
    hostname=MSK-R15.otus.local
    cn=MSK-R15
    ou=VPN
    o=Otus
    c=RU
  Validity Date:
    start date: 23:11:45 MSK Dec 10 2024
    end   date: 23:11:45 MSK Dec 10 2025
  Associated Trustpoints: VPN

CA Certificate
  Status: Available
  Certificate Serial Number (hex): 01
  Certificate Usage: Signature
  Issuer:
    cn=CA
  Subject:
    cn=CA
  Validity Date:
    start date: 23:05:26 MSK Dec 10 2024
    end   date: 23:05:26 MSK Dec 10 2027
  Associated Trustpoints: VPN
  Storage: nvram:CA#1CA.cer
```
Настройка  на  MSK-R15 и SPB-R18:
```cfg
crypto ikev2 profile IKEv2PROFILE-SPB
 match identity remote address 10.78.254.1 255.255.255.255
 authentication remote rsa-sig
 authentication local rsa-sig
 pki trustpoint VPN

crypto ikev2 profile IKEv2PROFILE-MSK
 match identity remote address 10.77.254.33 255.255.255.255
 authentication remote rsa-sig
 authentication local rsa-sig
 pki trustpoint VPN
```
Поверка
```cfg
SPB-R18(config-if)#do  sh crypto ikev2 ses
 IPv4 Crypto IKEv2 Session

Session-id:3, Status:UP-ACTIVE, IKE count:1, CHILD count:1

Tunnel-id Local                 Remote                fvrf/ivrf            Status
1         10.78.254.1/500       10.77.254.33/500      none/none            READY
      Encr: AES-CBC, keysize: 128, PRF: MD5, Hash: MD596, DH Grp:2, Auth sign: RSA, Auth verify: RSA
      Life/Active Time: 86400/99 sec
Child sa: local selector  10.78.254.1/0 - 10.78.254.1/65535
          remote selector 10.77.254.33/0 - 10.77.254.33/65535
          ESP spi in/out: 0x72F9A6E9/0xA05AE01F

 IPv6 Crypto IKEv2 Session
```
Как можно видеть используются сертификаты - "Auth sign: RSA, Auth verify: RSA"

Для DMVPN настройка аналогичная, поэтому проверка и вывод:
```cfg
MSK-R15(config-ikev2-profile)#
MSK-R15(config-ikev2-profile)#do  ping 172.16.255.27
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 172.16.255.27, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 5/5/6 ms
MSK-R15(config-ikev2-profile)#do  ping 172.16.255.28
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 172.16.255.28, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 5/5/6 ms
MSK-R15(config-ikev2-profile)#do  sh crypto ikev2 ses
 IPv4 Crypto IKEv2 Session

Session-id:2, Status:UP-ACTIVE, IKE count:1, CHILD count:1

Tunnel-id Local                 Remote                fvrf/ivrf            Status
2         10.77.254.33/500      10.0.254.89/500       none/none            READY
      Encr: AES-CBC, keysize: 128, PRF: MD5, Hash: MD596, DH Grp:2, Auth sign: PSK, Auth verify: PSK
      Life/Active Time: 86400/2243 sec
Child sa: local selector  10.77.254.33/0 - 10.77.254.33/65535
          remote selector 10.0.254.89/0 - 10.0.254.89/65535
          ESP spi in/out: 0xE0C1E232/0x72AE893A

Session-id:3, Status:UP-ACTIVE, IKE count:1, CHILD count:1

Tunnel-id Local                 Remote                fvrf/ivrf            Status
3         10.77.254.33/500      10.0.254.141/500      none/none            READY
      Encr: AES-CBC, keysize: 128, PRF: MD5, Hash: MD596, DH Grp:2, Auth sign: PSK, Auth verify: PSK
      Life/Active Time: 86400/2236 sec
Child sa: local selector  10.77.254.33/0 - 10.77.254.33/65535
          remote selector 10.0.254.141/0 - 10.0.254.141/65535
          ESP spi in/out: 0x143C7AC2/0x5F4C40B3

Session-id:4, Status:UP-ACTIVE, IKE count:1, CHILD count:1

Tunnel-id Local                 Remote                fvrf/ivrf            Status
1         10.77.254.33/500      10.78.254.1/500       none/none            READY
      Encr: AES-CBC, keysize: 128, PRF: MD5, Hash: MD596, DH Grp:2, Auth sign: RSA, Auth verify: RSA
      Life/Active Time: 86400/588 sec
Child sa: local selector  10.77.254.33/0 - 10.77.254.33/65535
          remote selector 10.78.254.1/0 - 10.78.254.1/65535
          ESP spi in/out: 0xA05AE01F/0x72F9A6E9

 IPv6 Crypto IKEv2 Session

```

### Конфиги устройств:
- [R15](R15)
- [R18](R18)
- [R27](R27)
- [R28](R28)
