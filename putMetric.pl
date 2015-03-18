#! /usr/bin/perl

use strict;
use warnings;

use IO::Socket;
use Time::HiRes qw(usleep nanosleep);

# ��������� ������ ��� ������ � MySQL
use DBI;
use Time::HiRes qw( gettimeofday tv_interval);

# ������ ��� MySQL
my $db_host = "localhost";
my $db_port = "3306";
my $db_user = "rrl";          # ��� ������������
my $db_pass = "rrl_pass";     # ������
my $db      = "RRLTraffic";

#my $id_if = $ARGV[0];    # ID ���������� ��  InterfaceHost.id

my $count=0;

# ������ �����
my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
  localtime time;
$year = $year + 1900;
$mon  = $mon + 1;
my $unix_time       = time;
my $start_unix_time = time;



# Hash of hosts and location data.

my $dbh = DBI->connect( "DBI:mysql:$db:$db_host:$db_port", $db_user, $db_pass )
  or die "Unable to connect: $DBI::errstr\n";


# ��������� ���������� ��������		
		my $MySQL_query1 ="SELECT  a.metric,a.SNMP_unix_time,a.IFspeed,a.interval_measure,a.InHighOctets,a.OutHighOctets,a.InDiscards,a.OutDiscards,a.InErrors,a.OutErrors FROM View_Metric_last10min as a ";
      
  
#and a.SNMP_time='16:40:00'
    my $sth1 = $dbh->prepare("$MySQL_query1") or die "Error: $DBI::errstr\n";
    $sth1->execute or die "Unable to execute '$MySQL_query1'.  " . $sth1->errstr;
     #print "$MySQL_query1\n";

my $socket = IO::Socket::INET->new(
   PeerAddr=> "localhost",
   PeerPort => 2003,
   Proto => 'tcp',
   Timeout => 10,
   Type => SOCK_STREAM) || die "$!\n";

# ��� ������ ������ SELECT (���� ������ ���� ����) ������� �������
    while (my $res1 = $sth1->fetchrow_arrayref ) {

        my (
            $DB_SNMP_unix_time, $DB_metric,  $DB_IFSpeed,   $DB_interval,
            $DB_InHighOctets, $DB_OutHighOctets,
            $DB_InDiscards,     $DB_OutDiscards,  $DB_InErrors,
            $DB_OutErrors
          )
          = ($$res1[1], $$res1[0], $$res1[2], $$res1[3], $$res1[4],
            $$res1[5], $$res1[6], $$res1[7], $$res1[8], $$res1[9]);
	
   # $DB_metric=~s/\//-/g;
      my $trafin=$DB_InHighOctets*8/$DB_interval;
      my $trafOut=$DB_OutHighOctets*8/$DB_interval;
 	$count= $count+9; 
  my $BeginMetric="Yaroslavl.RRL";
   print $socket  "$BeginMetric.$DB_metric.Ifspeed  $DB_IFSpeed $DB_SNMP_unix_time\n";
   print   "$BeginMetric.$DB_metric.Ifspeed  $DB_IFSpeed $DB_SNMP_unix_time\n";
   print $socket "$BeginMetric.$DB_metric.InOctets  $DB_InHighOctets $DB_SNMP_unix_time\n";
   print $socket "$BeginMetric.$DB_metric.OutOctets  $DB_OutHighOctets $DB_SNMP_unix_time\n";
   print $socket  "$BeginMetric.$DB_metric.InDiscards  $DB_InDiscards $DB_SNMP_unix_time\n";   
   print $socket  "$BeginMetric.$DB_metric.OutDiscards  $DB_OutDiscards $DB_SNMP_unix_time\n";     
   print $socket  "$BeginMetric.$DB_metric.InErrors  $DB_InErrors $DB_SNMP_unix_time\n";  
   print $socket "$BeginMetric.$DB_metric.OutErrors  $DB_OutErrors $DB_SNMP_unix_time\n";       
   print $socket  "$BeginMetric.$DB_metric.TrafIn  $trafin $DB_SNMP_unix_time\n";  
   print $socket  "$BeginMetric.$DB_metric.TrafOut  $trafOut $DB_SNMP_unix_time\n"; 
  # usleep(100000);    
    
     
}


$sth1->finish;        # ���������
$dbh->disconnect;    # ����������
print "count metric:$count\n";

exit 0;

sub netcat {
    my $c = qq{echo  $_[0] | nc -C  localhost 2003}; 
     system( $c);
     print " $c\n"     
}