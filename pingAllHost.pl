#!/usr/bin/perl -w

my $host = "localhost";
my $port = "3306"
  ;    # порт, на который открываем соединение
my $user = "rrl";         # имя пользователя
my $pass = "rrl_pass";    # пароль
my $db   = "RRLTraffic"
  ; # имя базы данных -по умолчанию равно имени пользователя

#my $SNMP_host = $ARGV[0];    # IP Addres

use Time::HiRes;

# подрубаем модуль для работы с MySQL
use DBI;

use Net::Ping;

$dbh = DBI->connect( "DBI:mysql:$db:$host:$port", $user, $pass )
  or die "Unable to connect: $DBI::errstr\n";

# получаем ip опроса

$sth = $dbh->prepare( "select  hostname from  host order by hostname" )
  ;    # готовим запрос
$sth->execute or die "Error: $DBI::errstr\n";

# проходим по всем ip из таблицы
while ( $ref = $sth->fetchrow_arrayref ) {

    my ($SNMP_host) = ( $$ref[0] );

   # пингуем ip
	$p = Net::Ping->new();
    $p->hires();
    ( $ret, $duration, $ip ) = $p->ping( $SNMP_host, 2 );
    $p->close();

	
    if ($ret) {

        printf( "$SNMP_host [ip: $ip] is alive (packet return time: %.2f ms)\n",
            1000 * $duration );

        $dbh = DBI->connect( "DBI:mysql:$db:$host:$port", $user, $pass )
          or die "Unable to connect: $DBI::errstr\n";
        $MySQL_query =
            "UPDATE  `host` SET  `ping` =  '"
          . 100000 * $duration
          . "' WHERE  hostname =\""
          . $ip . "\";";

        #print "$MySQL_query";
        $dbh->do("$MySQL_query") or die "Error: $DBI::errstr\n";

    }
    else {
        printf("$SNMP_host [ip: $ip] is NOT alive\n");
    }
}
$dbh->disconnect;
1;
