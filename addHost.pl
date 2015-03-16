#!/usr/bin/perl -w

my $host = "localhost";
my $port = "3306"
  ;    # порт, на который открываем соединение
my $user = "rrl";         # имя пользователя
my $pass = "rrl_pass";    # пароль
my $db   = "RRLTraffic"
  ; # имя базы данных -по умолчанию равно имени пользователя
my $SNMP_host = $ARGV[0];    # IP Addres


my $OID_get = '1.3.6.1.2.1.1.5.0';# name site
my $Name_Host=$SNMP_host;

# подрубаем модуль, отвечающий за SNMP
use Net::SNMP;

# подрубаем модуль для работы с MySQL
use DBI;

use Net::Ping;

my $p = Net::Ping->new();
if ($p->ping($SNMP_host, 2))
	{ 
		print "OK!!!";
my ( $session, $error ) = Net::SNMP->session(
        -hostname => $SNMP_host,
        -version  => 'snmpv3',

        #	-community => 'public',
        -username => 'control_user',

        #      -authprotocol => 'sha1',
        #      -authkey      => '0x34dc843c09629897264ac0d7a1c9def7',
        -authpassword => 'ericsson',

        # используем snmpkey c EngineID OCTET STRING ::= '8000000006'H
        #      -privprotocol => 'des',
        #      -privkey      => '0x6695febc9288e36282235fc7151f1284',
    );

    if ( !defined $session ) {
        printf "ERROR: %s.\n", $error;
        exit 1;
    }

   $result =
      $session->get_request( -varbindlist => [ $OID_get  ], );
    if ( defined $result ) {
        if ( $result->{ $OID_get } ne 'noSuchObject' ) {
            $Name_host = $result->{ $OID_get };
        }

    }


$session->close();

 print "$Name_host\n";

$dbh = DBI->connect( "DBI:mysql:$db:$host:$port", $user, $pass )
  or die "Unable to connect: $DBI::errstr\n";
$MySQL_query="INSERT INTO `host` ( `description`, `hostname`, `snmp_version`, `snmp_username`, `snmp_password`, `snmp_port`, `snmp_timeout`) VALUES ( '".$Name_host."', '".$SNMP_host."',  '3', 'control_user', 'ericsson', '161', '2000');";
 $dbh->do("$MySQL_query") or die "Error: $DBI::errstr\n";






$dbh->disconnect;  



} else {
print "Host: $SNMP_host not alive. "} 
 1;


 
1;
