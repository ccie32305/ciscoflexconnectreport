# ciscoflexconnectreport
Get a Report from auch Cisco WLC about Flexconnect WLAN-VLAN Mapping
Usage: ciscoflexconnectreport.pl <OPTIONS>

-wlc <IP/HOST> - IP or DNS name of WLC
-user <USER> - WLC username
-pass <PASSWORD> - WLC password
-smtp <IPZHOST> IP or DNS name of mailserver
-from <EMAIL> - email address from server
-to <EMAIL> - email address of report receiver


The report will send you a mail containing a structured list of all APs with their configured WLAN mapping.
This tool was written because of 
- CSCur68316 - 802AP-891 in flexconnect mode are losing vlan mapping after power cycle
- CSCuu97071 - DOC.AP in flexconnect mode losses vlan mapping
- CSCuc35382 - NCS 1.1 - Lost FlexConnect VLAN-Mapping AP Template if not shown in GUI
- Support Forum entries - https://supportforu*s.c*sco.com/discussion/11837926/lost-vlan-mapping-wlc-5508-flexconnect
and many other undocumented bugs, complaints and problems in daily work with big WLC Flexconnect installations
