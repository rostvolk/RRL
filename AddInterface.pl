#!/usr/bin/perl -w


#опрашивает по SNMP интерфесы для HOST и заносим в базу InterfaceHost
# host получаем по ID из базы host
# use getinteface.pl ID


my $host = "localhost";
my $port = "3306"; # порт, на который открываем соединение
my $user = "rrl"; # имя пользователя 
my $pass = "rrl_pass"; # пароль
my $db = "RRLTraffic"; 
my $id_host= $ARGV[0];
 if (!$id_host) {die "usage AddInterface <id host>";
 }

	my $OID_IPaddr='.1.3.6.1.2.1.14.1.1.0';
	my $OID_get = '1.3.6.1.2.1.1.5.0';# name site
	my $OID_IfType = '1.3.6.1.2.1.2.2.1.3.';
	my $OID_IfTypeName = '1.3.6.1.2.1.2.2.1.2.'; #IF-MIB::ifDescr
	my $OID_IfName = '1.3.6.1.2.1.31.1.1.1.1.';
    my $OID_IfDesc = '1.3.6.1.2.1.31.1.1.1.18.';#ifAlias
	my $OID_IfState='1.3.6.1.2.1.2.2.1.8.';
	my $OID_IfMin='1.3.6.1.2.1.2.2.1.5.';
    my $OID_IfMax='1.3.6.1.2.1.31.1.1.1.15.';
    my $OID_ind_part= '1.3.6.1.2.1.17.1.4.1.2.';#list int



# подрубаем модуль,q отвечающий за SNMP
use Net::SNMP;
# подрубаем модуль для работы с MySQL
use DBI;

# достаём время
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
$year = $year + 1900;
$mon = $mon + 1;
my $unix_time = time;





$dbh = DBI->connect("DBI:mysql:$db:$host:$port",$user,$pass) or die "Unable to connect: $DBI::errstr\n";
$sth = $dbh->prepare("select hostname,snmp_username,snmp_password from host where id=".$id_host);# готовим запрос

$sth->execute; # исполняем запрос

# 
while ($ref = $sth->fetchrow_arrayref) {
	print "$$ref[0] $$ref[1] $$ref[2]\n"; # печатаем результат

	my $SNMP_host=$$ref[0];
	my $SNMP_user=$$ref[1];
	my $SNMP_pass=$$ref[2];

	my $OID_ind;
	my ($session, $error) = Net::SNMP->session(
      -hostname     =>  $SNMP_host,
      -version      => 'snmpv3',
#	-community => 'public',
      -username     => $SNMP_user,
#      -authprotocol => 'sha1',
#      -authkey      => '0x34dc843c09629897264ac0d7a1c9def7',
		-authpassword  => $SNMP_pass,	
# используем snmpkey c EngineID OCTET STRING ::= '8000000006'H
#      -privprotocol => 'des',
#      -privkey      => '0x6695febc9288e36282235fc7151f1284',
   );

   if (!defined $session) {
      printf "ERROR: %s.\n", $error;
      exit 1;
	}

#отсылаем запрос на имя 
    my $result = $session->get_request(-varbindlist => [ $OID_get ],);

   if (!defined $result) {
      printf "ERROR: %s.\n", $session->error();
      $session->close();
      exit 1;
   }
	my $host_name1=$result->{$OID_get};


   $result = $session->get_request(-varbindlist => [ $OID_IPaddr ],);
   my $If_IPaddr=$result->{$OID_IPaddr};

#перебираем все интерфейсы
for($i = 1; $i < 26; $i++){
#формируем нужный OID
	$OID_ind=$OID_ind_part.$i;
#отсылка SMTP запроса
 	my $result = $session->get_request(-varbindlist => [ $OID_ind ],);
	#проверяем результат на корректоность
  	 if (defined $result) {
   		if ($result->{$OID_ind} > 0){

			#printf "$OID_ind - $result->{$OID_ind} \n";
			my $If_ind=$result->{$OID_ind};
		 	 $result = $session->get_request(-varbindlist => [ $OID_IfName.$If_ind ],);
			my $If_Name=$result->{$OID_IfName.$If_ind};
			 $result = $session->get_request(-varbindlist => [ $OID_IfType.$If_ind ],);
			my $If_Type=$result->{$OID_IfType.$If_ind};
			
			 $result = $session->get_request(-varbindlist => [ $OID_IfTypeName.$If_ind ],);
			my $If_TypeName=$result->{$OID_IfTypeName.$If_ind};

			
			$result = $session->get_request(-varbindlist => [ $OID_IfDesc.$If_ind ],);
            my $If_Desc=$result->{$OID_IfDesc.$If_ind};
  			$result = $session->get_request(-varbindlist => [ $OID_IfState.$If_ind ],);
            if (defined $result) {
				$If_State=$result->{$OID_IfState.$If_ind};
				}
           $result = $session->get_request(-varbindlist => [ $OID_IfMax.$If_ind ],);
               my $If_Max=$result->{$OID_IfMax.$If_ind};
                        $result = $session->get_request(-varbindlist => [ $OID_IfMin.$If_ind ],);
                 if (defined $result) {
					 $If_Min=$result->{$OID_IfMin.$If_ind};}


 			printf "'%s' -  %s -",$session->hostname(), $host_name1;

 printf "$If_IPaddr- $If_ind -  $If_Name - $If_Type - $If_Desc- $If_State-$If_Min- $If_Max\n";

my $QueryStr="INSERT INTO `Interface` ( `ifOID`, `ifName`, `ifType`,`ifTypeName`, `ifSpeed`, `ifDescr`, `hostname`, `iphostname`, `Host_id`, `ifState`) VALUES ( ".$If_ind.", '".$If_Name."', ".$If_Type.", '".$If_TypeName."', ".$If_Min.", '".$If_Desc."', '".$host_name1."', '".$If_IPaddr."', ".$id_host.", ".$If_State.");";


my $qs=$dbh->quote($QueryStr);
my $qs1=$dbh->prepare($QueryStr);

$qs1->execute; # исполняем запрос

			}		
		}		
	}	

#   printf "host '%s' is %s.\n",
#          $session->hostname(), $host_name1;

 
  $session->close();


}

$rc = $sth->finish;    # закрываем
$rc = $dbh->disconnect;  # соединение





1;
