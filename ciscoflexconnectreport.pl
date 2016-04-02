#!/usr/bin/perl
# ciscoflexconnectreport.pl - v0.1
#
# Git repository available at https://github.com/ccie32305/ciscoflexconnectreport
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Donate via twitter @ccie32305
#

use Net::SSH::Expect;
use Net::SMTP;
use Getopt::Long qw(GetOptions);
my $frommail;
my $wlc;
my $user;
my $pass;
my $smtpip;
my $tomail;
GetOptions('from=s' => \$frommail,
	   'wlc=s' => \$wlc,
	   'user=s' => \$user,
	   'pass=s' => \$pass,
	   'smtp=s' => \$smtpip,
	   'to=s' => \$tomail) or die "Usage: $0 <OPTIONS>\n\n-wlc <IP/HOST> - IP or DNS name of WLC\n-user <USER> - WLC username\n-pass <PASSWORD> - WLC password\n-smtp <IPZHOST> IP or DNS name of mailserver\n-from <EMAIL> - email address from server\n-to <EMAIL> - email address of report receiver ";
if ($frommail && $wlc && $user && $pass && $smtpip && $tomail) {
my $ssh = Net::SSH::Expect->new (
 host => $wlc,
  raw_pty => 1
  );

#  print ("Getting into WLC...\n");
  $ssh->run_ssh() or die "SSH process couldn't start: $!";
  $ssh->waitfor('User:', 10) or die "prompt 'User' not found after 10 second";
  $ssh->send($user);
  $ssh->waitfor('Password:', 3) or die "prompt 'Password' not found after 3 second";
  $ssh->send($pass);
  $ssh->waitfor('>', 3) or die "prompt 'Cisco Controller' not found";
########################
# Getting all WLANS
# 
#  print "Getting all WLANS...\n";
  my $wlan = $ssh->exec("show wlan summary");
my $i;
my @ssids;
while($wlan =~ /([^\n]+)\n?/g){
	my $line=$1;
	if(substr($line,0,1) =~ /^\d+$/ )
	{
	        $ssid = substr($line,index($line," / ")+3,20);
		$ssid = substr($ssid,0,index($ssid,"   "));
		$ssids[substr($line,0,2)] = $ssid;
#		print "\nWLANIDS:".substr($line,0,2);	
	}
}
#######################
# Getting AP count Access-Points
#
$ssh->send("config paging disable");
$ssh->waitfor('>', 3) or die "prompt 'Cisco Controller' not found";
my $ap = $ssh->exec("show ap summary");
my @ap = split(/\n/, $ap);
foreach $line (@ap) {
if(substr($line,0,13) eq "Number of APs")
{
		my ($apcount) = $line =~ /(\d+)/;
#		print "APCOUNT:".$apcount."\n";
}
}	
########################
## Getting all AP names
##
#
my $i;
my @apconfig;
my $count = 9; 
#print "Getting all AP names\n";
splice @ap, 0, $count;
splice @ap, -3;
foreach $line (@ap) {
        my (@apnames) = split /\s{2,}/, $line;
	$apconfig[$i] = $ssh->exec("show ap config general ".@apnames[0]);
	$i++;
}


######################
## Flexconnect VLAN Mapping
#
$i=0;
my @flexconnectdata;
foreach $string (@apconfig) {

# Check if we have a Flexconnect AP
#
if(index($string,"AP Mode ......................................... FlexConnect") ne -1)
{
$i++;

#print "Flexconnect AP\n";
$apname = substr($string,index($string,"AP Name")+44,35);
$apname2 = substr($apname,0,index($apname,"Country")-1);
$flexconnectdata[$i][0] = $apname2;

#
# Retrieve Flexconnect VLANs
#
$string = substr($string,index($string,"Native ID :"));
$string = substr($string,0,index($string,"FlexConnect VLAN ACL"));

my @lines = split /\n/, $string;
foreach my $line (@lines) {
#$i++;
if(index($line,"WLAN") ne -1)
{
#  Get WLAN IDs out of AP config
#
my $wlanidstring = substr($line,index($line,"WLAN"),index($line,"WLAN")+6);
$wlanidstring =~ tr/0-9//cd;
# Get WLAN ID VLAN 
#
my $wlanidvlanteil = substr($line,index($line,"..... ")+6,4);
my $wlanidvlan = substr($wlanidvlanteil,0,index($wlanidvlanteil," "));
#print "\nVLAN'".$wlanidvlan."'";
$flexconnectdata[$i][$wlanidstring] = $wlanidvlan;

 }
 }

 }
 else
 {
 print "No Flexconnect AP\n";
}

}
$html = "\n<html><table><tr>";
foreach $ssid (@ssids) {
$html = $html."<TD>".$ssid."</TD>";
}
$html = $html."</TR>";
foreach my $ref_zeile (@flexconnectdata) { 
	$i=0;
    foreach (@ssids)
	{
    $html=$html."<TD>".@{$ref_zeile}[$i]."</TD>";
        $i++;	
	}
    $html=$html."</TR>\n\n";
}
######################
#    Send MAIL
#
 my $smtp = Net::SMTP->new('adesmtp1');
    $smtp->mail($frommail);
   $smtp->to($tomail);
     $smtp->data();
    $smtp->datasend("Subject:Flexconnect-Report:".$wlc."\n");
    $smtp->datasend("MIME-Version: 1.0\nContent-Type: text/html; charset=UTF-8 \n\n<H1>");
     $smtp->datasend($html);
        $smtp->datasend();
        $smtp->quit;
 

######################
# Session beenden
$ssh->send("logout");
}
else
{
print "Usage: $0 <OPTIONS>\n\n-wlc <IP/HOST> - IP or DNS name of WLC\n-user <USER> - WLC username\n-pass <PASSWORD> - WLC password\n-smtp <IPZHOST> IP or DNS name of mailserver\n-from <EMAIL> - email address from server\n-to <EMAIL> - email address of report receiver\n";
}
