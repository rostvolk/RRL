#! /usr/local/bin/perl

use strict;
use warnings;

use Net::SNMP;

# подрубаем модуль для работы с MySQL
use DBI;
use Time::HiRes qw( gettimeofday tv_interval);

# данные для MySQL
my $db_host = "localhost";
my $db_port = "3306";
my $db_user = "rrl";          # имя пользователя
my $db_pass = "rrl_pass";     # пароль
my $db      = "RRLTraffic";

#my $id_if = $ARGV[0];    # ID интерфейса из  InterfaceHost.id

my $OID_IfSpeed       = '1.3.6.1.2.1.2.2.1.5.';
my $OID_InOctets      = '1.3.6.1.2.1.2.2.1.10.';
my $OID_OutOctets     = '1.3.6.1.2.1.2.2.1.16.';
my $OID_InHighOctets  = '1.3.6.1.2.1.31.1.1.1.6.';
my $OID_OutHighOctets = '1.3.6.1.2.1.31.1.1.1.10.';
my $OID_InDiscards    = '1.3.6.1.2.1.2.2.1.13.';
my $OID_OutDiscards   = '1.3.6.1.2.1.2.2.1.19.';
my $OID_InErrors      = '1.3.6.1.2.1.2.2.1.14.';
my $OID_OutErrors     = '1.3.6.1.2.1.2.2.1.20.';

# достаём время
my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
  localtime time;
$year = $year + 1900;
$mon  = $mon + 1;
my $unix_time       = time;
my $start_unix_time = time;

my $OID_sysUpTime   = '1.3.6.1.2.1.1.3.0';
my $OID_sysContact  = '1.3.6.1.2.1.1.4.0';
my $OID_sysLocation = '1.3.6.1.2.1.1.6.0';

# Hash of hosts and location data.

my $dbh = DBI->connect( "DBI:mysql:$db:$db_host:$db_port", $db_user, $db_pass )
  or die "Unable to connect: $DBI::errstr\n";

# получаем ip, user и snmp_pass для snmp опроса

my $sth = $dbh->prepare(
"SELECT Interface.id, Interface.ifOID,  host.hostname, host.snmp_username, host.snmp_password,host.id,host.snmp_timeout 	FROM Interface, host	WHERE Interface.host_id = host.id and Interface.ifState=1"
);    # готовим запрос
$sth->execute or die "Error: $DBI::errstr\n";

#формируем хэш из select
my %myint = ();
while ( my @row = $sth->fetchrow_array ) {

    #print "$row[0]\t$row[1]\t$row[2]\n";
    $myint{ $row[0] }{'ip'}     = $row[2];
    $myint{ $row[0] }{'user'}   = $row[3];
    $myint{ $row[0] }{'pass'}   = $row[4];
    $myint{ $row[0] }{'hostid'} = $row[5];
    $myint{ $row[0] }{'OID'}    = $row[1];
    $myint{ $row[0] }{'timeout'} = $row[6];
}

# выводим хэ на экран
#   while ( my ($key) = each(%myint) ) {
#        print "$key\t$myint{$key}{'ip'}\t$myint{$key}{'OID'}\t$myint{$key}{'hostid'}\n";
#    }

#размер хэша
#print "size of hash:  " . keys(%myint) . ".\n";

# сортированныый хэш
# for my $id (sort keys %myint) {
#  print "$id\t$myint{$id}{'ip'}\t$myint{$id}{'OID'}\t$myint{$id}{'hostid'}\n";
# }




for my $id ( keys %myint ) {

    my ( $session, $error ) = Net::SNMP->session(
        -hostname     => $myint{$id}{'ip'},
        -version      => 'snmpv3',
        -username     => $myint{$id}{'user'},
        -authpassword => $myint{$id}{'pass'},
        -nonblocking  => 1,
        -timeout       => $myint{$id}{'timeout'}/1000,
    );
#    print "qued: $id\t$myint{$id}{'ip'}\t$myint{$id}{'OID'}\t$myint{$id}{'hostid'}\n";

    if ( !defined $session ) {
        printf "ERROR: Failed to create session for host '%s': %s.\n",
          $myint{$id}{'ip'}, $error;
        next;

    }

#формируем SNMP запрос

	my $result = $session->get_request(
        -varbindlist => [ $OID_sysUpTime,
				$OID_sysContact, 
				$OID_sysLocation,
				$OID_IfSpeed.$myint{$id}{'OID'},
				$OID_InOctets.$myint{$id}{'OID'},
		      $OID_OutOctets.$myint{$id}{'OID'},
				$OID_InHighOctets.$myint{$id}{'OID'},
				$OID_OutHighOctets.$myint{$id}{'OID'},
				$OID_InDiscards.$myint{$id}{'OID'},
				$OID_OutDiscards.$myint{$id}{'OID'},
				$OID_InErrors.$myint{$id}{'OID'},
				$OID_OutErrors.$myint{$id}{'OID'}, 
   			 ],
        -callback    => [ \&get_callback, $myint{$id}{'OID'} ,$id,$myint{$id}{'hostid'}],
    );

    if ( !defined $result ) {
        printf "ERROR: Failed to queue get request for host '%s': %s.\n",
          $session->hostname(), $session->error();
    }

}

# Now initiate the SNMP message exchange.


#my ( $starts, $startusec ) = gettimeofday();
my $t0 = [gettimeofday];
snmp_dispatcher();

$sth->finish;        # закрываем
$dbh->disconnect;    # соединение

exit 0;

sub get_callback {
   my ( $session, $OID ,$id,$hostid) = @_;
   my $result = $session->var_bind_list();

   if ( !defined $result ) {
        printf "%02d.%02d.%d %02d:%02d\tERROR: Get request failed for host '%s': %s.\n",
        $mday, $mon,$year, $hour,$min, $session->hostname(), $session->error();
        return;
   }

    
   
#	printf "The sysUpTime for host '%s' id:%s is %s %s %s \ttime:%.3fsec  \n",
#      $session->hostname(),$id, $result->{$OID_sysUpTime},
#      $result->{$OID_sysContact}, $result->{$OID_sysLocation},
#      $t0_t1;

   my $If_InOctets      = 0;
   my $If_OutOctets     = 0;
   my $If_InHighOctets  = 0;
   my $If_OutHighOctets = 0;
   my $If_InDiscards    = 0;
   my $If_OutDiscards   = 0;
   my $If_InErrors      = 0;
   my $If_OutErrors     = 0;
   my $If_Speed         = 0;


   #присваиваем значения полученные из SNMP при условии что они есть
   
   $If_Speed  = $result->{ $OID_IfSpeed  . $OID } if ($result->{ $OID_IfSpeed . $OID }ne 'noSuchObject' )  ;

   $If_InOctets = $result->{ $OID_InOctets . $OID } if ($result->{ $OID_InOctets . $OID }ne 'noSuchObject' )  ;
   $If_OutOctets = $result->{ $OID_OutOctets . $OID } if ($result->{ $OID_OutOctets . $OID }ne 'noSuchObject' )  ;   

   $If_InHighOctets = $result->{ $OID_InHighOctets . $OID } if ($result->{ $OID_InHighOctets . $OID }ne 'noSuchObject')     ;   
   $If_OutHighOctets = $result->{ $OID_OutHighOctets . $OID } if ($result->{ $OID_OutHighOctets . $OID }ne 'noSuchObject')  ;   

   $If_InDiscards = $result->{ $OID_InDiscards . $OID } if ($result->{ $OID_InDiscards . $OID }ne 'noSuchObject')  ;   
   $If_OutDiscards = $result->{ $OID_OutDiscards . $OID } if ($result->{ $OID_OutDiscards . $OID }ne 'noSuchObject')  ;   

   $If_InErrors = $result->{ $OID_InErrors . $OID } if ($result->{ $OID_InErrors . $OID }ne 'noSuchObject')  ;   
   $If_OutErrors = $result->{ $OID_OutErrors . $OID } if ($result->{ $OID_OutErrors . $OID }ne 'noSuchObject')  ;   

	
#	printf "SNMP request: Ifspeed:$If_Speed\n";
#	printf "in/out    :$If_InOctets/$If_OutOctets\n";
#    printf "64 in/out :$If_InHighOctets/$If_OutHighOctets\n";
#    printf "Discard   :$If_InDiscards/$If_OutDiscards\n";
#    printf "Error     :$If_InErrors/$If_OutErrors\n";


# извлекаем предыдущие значения		
		my $MySQL_query1 ="SELECT  `SNMP_unix_time` ,  `Interface_id` ,`Interface_host_id`,  `InOctets` ,  `OutOctets` ,  `InHighOctets` ,  `OutHighOctets` ,  `InDiscards` ,  `OutDiscards` ,`InErrors` , `OutErrors` FROM  `SNMP_tmp_table` WHERE  `Interface_id` = '". $id. "' ORDER BY  `SNMP_unix_time` DESC LIMIT 1";

    my $sth1 = $dbh->prepare("$MySQL_query1") or die "Error: $DBI::errstr\n";
    $sth1->execute or die "Unable to execute '$MySQL_query1'.  " . $sth1->errstr;
#print "$MySQL_query1\n";

# для каждой строки SELECT (одна должна быть одна) считаем разницу
    while (my $res1 = $sth1->fetchrow_arrayref ) {

        my (
            $DB_SNMP_unix_time, $DB_InterfaceID,  $DB_InterfaceHostID,   $DB_InOctets,
            $DB_OutOctets,      $DB_InHighOctets, $DB_OutHighOctets,
            $DB_InDiscards,     $DB_OutDiscards,  $DB_InErrors,
            $DB_OutErrors
          )
          = (
            $$res1[0], $$res1[1], $$res1[2], $$res1[3], $$res1[4],
            $$res1[5], $$res1[6], $$res1[7], $$res1[8], $$res1[9], $$res1[10]
          );
	
#        printf "Select from SNMP_temp\n";
#		printf "$DB_SNMP_unix_time\nin/out    :$DB_InOctets/$DB_OutOctets\n";
#      printf "64 in/out :$DB_InHighOctets/$DB_OutHighOctets\n";
#      printf "Discard   :$DB_InDiscards/$DB_OutDiscards\n";
#        printf "Error     :$DB_InErrors/$DB_OutErrors\n";

        my $Delta_InOctets      = 0;
        my $Delta_OutOctets     = 0;
        my $Delta_InHighOctets  = 0;
        my $Delta_OutHighOctets = 0;
        my $Delta_InDiscards    = 0;
        my $Delta_OutDiscards   = 0;
        my $Delta_InErrors      = 0;
        my $Delta_OutErrors     = 0;

# считаем дельту при условии, что счетчик больше(не сбрасывался).
		 $Delta_InOctets = $If_InOctets - $DB_InOctets      if ( $If_InOctets >= $DB_InOctets );
       $Delta_OutOctets = $If_OutOctets - $DB_OutOctets     if ( $If_OutOctets >= $DB_OutOctets );
       $Delta_InHighOctets = $If_InHighOctets - $DB_InHighOctets     if ( $If_InHighOctets >= $DB_InHighOctets );
		 $Delta_OutHighOctets = $If_OutHighOctets - $DB_OutHighOctets   if ( $If_OutHighOctets >= $DB_OutHighOctets );
       $Delta_InDiscards = $If_InDiscards - $DB_InDiscards        if ( $If_InDiscards >= $DB_InDiscards );
       $Delta_OutDiscards = $If_OutDiscards - $DB_OutDiscards     if ( $If_OutDiscards >= $DB_OutDiscards );
       $Delta_InErrors = $If_InErrors - $DB_InErrors         if ( $If_InErrors >= $DB_InErrors );
       $Delta_OutErrors = $If_OutErrors - $DB_OutErrors      if ( $If_OutErrors >= $DB_OutErrors );

		 my $interval_measure = $unix_time - $DB_SNMP_unix_time;
	
        # засовываем даные в постоянную таблицу
      my  $MySQL_query2 =
"INSERT INTO `SNMP-Traffic` (`id`,`SNMP_date`,`SNMP_time`,`SNMP_unix_time`, `interface_id`,`interface_host_id`,  `IFspeed`, `interval_measure`, `InOctets`, `OutOctets`, `InHighOctets`, `OutHighOctets`, `InDiscards`, `OutDiscards`, `InErrors`, `OutErrors`) VALUES (NULL,'"
          . $year . "-". $mon . "-"
          . $mday . "','"
          . $hour . ":"
          . $min
          . ":00','". $unix_time . "','"
          . $id . "','"
		  . $hostid . "','"
          . $If_Speed . "','"
          . $interval_measure . "','"
          . $Delta_InOctets . "','"
          . $Delta_OutOctets . "','"
          . $Delta_InHighOctets . "','"
          . $Delta_OutHighOctets . "','"
          . $Delta_InDiscards . "','"
          . $Delta_OutDiscards . "','"
          . $Delta_InErrors . "','"
          . $Delta_OutErrors . "')";
#		  $dbh->do("$MySQL_query2") or die "Error: $DBI::errstr\n";


# выводим результат на экран
        my $t0_t1 = tv_interval $t0;
		#  print " $MySQL_query2\n";
		  printf( "%02d.%02d.%d %02d:%02d\t%d\t%d\t%d\t%d\t%d/%d\t %d/%d\t %d/%d\t %d/%d/ttime:%.3fsec \n",$mday, $mon,$year, $hour,$min,       $id, $hostid, $interval_measure,    $If_Speed,          
           $Delta_InOctets,$Delta_OutOctets,
           $Delta_InHighOctets,$Delta_OutHighOctets,
           $Delta_InDiscards,$Delta_OutDiscards,
           $Delta_InErrors,$Delta_OutErrors,
			  $t0_t1 );
		  
    }
    
      # Засовываем данные во временную таблицу
     my  $MySQL_query4 =
"REPLACE INTO `SNMP_tmp_table` (`SNMP_unix_time`, `Interface_id`,`Interface_Host_id`, `InOctets`, `OutOctets`, `InHighOctets`, `OutHighOctets`, `InDiscards`, `OutDiscards`, `InErrors`, `OutErrors`) VALUES ('"
          . $unix_time . "','"
          . $id . "','"
		  . $hostid . "','"
          . $If_InOctets . "','"
          . $If_OutOctets . "','"
          . $If_InHighOctets . "','"
          . $If_OutHighOctets . "','"
          . $If_InDiscards . "','"
          . $If_OutDiscards . "','"
          . $If_InErrors . "','"
          . $If_OutErrors . "') ";
#print "$MySQL_query4\n";
#         $dbh->do("$MySQL_query4") or die "Error: $DBI::errstr\n";
 

    $sth1->finish;
	
    return;
}

