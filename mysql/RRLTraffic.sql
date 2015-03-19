-- phpMyAdmin SQL Dump
-- version 4.0.10deb1
-- http://www.phpmyadmin.net
--
-- Хост: localhost
-- Время создания: Мар 19 2015 г., 15:04
-- Версия сервера: 5.5.41-0ubuntu0.14.04.1
-- Версия PHP: 5.5.9-1ubuntu4.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- База данных: `RRLTraffic`
--

-- --------------------------------------------------------

--
-- Структура таблицы `host`
--

CREATE TABLE IF NOT EXISTS `host` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `host_type` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `description` varchar(150) NOT NULL DEFAULT '',
  `hostname` varchar(250) DEFAULT NULL,
  `IndexPoint` int(5) NOT NULL,
  `addres` varchar(150) NOT NULL,
  `notes` text,
  `snmp_community` varchar(100) DEFAULT NULL,
  `snmp_version` tinyint(1) unsigned NOT NULL DEFAULT '3',
  `snmp_username` varchar(50) DEFAULT NULL,
  `snmp_password` varchar(50) DEFAULT NULL,
  `snmp_auth_protocol` char(5) DEFAULT '',
  `snmp_priv_passphrase` varchar(200) DEFAULT '',
  `snmp_priv_protocol` char(6) DEFAULT '',
  `snmp_context` varchar(64) DEFAULT '',
  `snmp_port` mediumint(5) unsigned NOT NULL DEFAULT '161',
  `snmp_timeout` mediumint(8) unsigned NOT NULL DEFAULT '2000',
  `disabled` char(2) DEFAULT NULL,
  `status` tinyint(2) NOT NULL DEFAULT '0',
  `status_fail_date` datetime DEFAULT NULL,
  `status_rec_date` datetime DEFAULT NULL,
  `status_last_error` varchar(255) DEFAULT '',
  `ping` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ipaddress` (`hostname`),
  KEY `disabled` (`disabled`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=179 ;

-- --------------------------------------------------------

--
-- Структура таблицы `Interface`
--

CREATE TABLE IF NOT EXISTS `Interface` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `host_id` mediumint(8) unsigned NOT NULL,
  `ifOID` varchar(30) NOT NULL DEFAULT '',
  `IfName` varchar(45) DEFAULT NULL,
  `ifType` int(11) NOT NULL DEFAULT '0',
  `IfTypeName` varchar(50) NOT NULL,
  `ifSpeed` int(11) DEFAULT '0',
  `ifDescr` varchar(100) DEFAULT NULL,
  `hostname` varchar(150) DEFAULT NULL,
  `iphostname` varchar(50) DEFAULT NULL,
  `ifState` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`id`,`host_id`),
  UNIQUE KEY `UnIntreface` (`host_id`,`ifOID`),
  KEY `fk_InterfaceHost_host_idx` (`host_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=615 ;

-- --------------------------------------------------------

--
-- Структура таблицы `marks`
--

CREATE TABLE IF NOT EXISTS `marks` (
  `id` int(3) DEFAULT NULL,
  `name` int(4) DEFAULT NULL,
  `descr` varchar(267) DEFAULT NULL,
  `scale1` int(2) DEFAULT NULL,
  `scale2` int(2) DEFAULT NULL,
  `lonlatarr` varchar(32) DEFAULT NULL,
  `lonL` varchar(11) DEFAULT NULL,
  `latT` varchar(11) DEFAULT NULL,
  `LonR` varchar(11) DEFAULT NULL,
  `LatB` varchar(11) DEFAULT NULL,
  `color1` int(11) DEFAULT NULL,
  `color2` int(11) DEFAULT NULL,
  `visible` varchar(4) DEFAULT NULL,
  `picname` varchar(15) DEFAULT NULL,
  `categoryid` int(1) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Структура таблицы `SNMP-Traffic`
--

CREATE TABLE IF NOT EXISTS `SNMP-Traffic` (
  `id` int(12) NOT NULL AUTO_INCREMENT,
  `SNMP_date` date NOT NULL,
  `SNMP_time` time NOT NULL,
  `SNMP_unix_time` int(32) NOT NULL,
  `SNMP_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `IFspeed` int(9) NOT NULL,
  `interval_measure` int(32) NOT NULL,
  `InOctets` int(255) NOT NULL,
  `OutOctets` int(255) NOT NULL,
  `InHighOctets` bigint(255) NOT NULL,
  `OutHighOctets` bigint(255) NOT NULL,
  `InDiscards` bigint(255) NOT NULL,
  `OutDiscards` bigint(255) NOT NULL,
  `InErrors` bigint(255) NOT NULL,
  `OutErrors` bigint(255) NOT NULL,
  `Interface_id` int(10) unsigned NOT NULL,
  `Interface_host_id` mediumint(8) unsigned NOT NULL,
  PRIMARY KEY (`id`,`Interface_id`,`Interface_host_id`),
  KEY `SNMP_unix_time` (`SNMP_unix_time`),
  KEY `SNMP_date` (`SNMP_date`),
  KEY `fk_SNMP-Traffic_Interface1_idx` (`Interface_id`,`Interface_host_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=koi8r COMMENT='Ð¢Ñ€Ð°Ñ„Ñ„Ð¸Ðº Ð¿Ð¾ SNMP' AUTO_INCREMENT=434172 ;

-- --------------------------------------------------------

--
-- Структура таблицы `SNMP_tmp_table`
--

CREATE TABLE IF NOT EXISTS `SNMP_tmp_table` (
  `SNMP_unix_time` int(255) NOT NULL,
  `InOctets` int(255) NOT NULL,
  `OutOctets` int(255) NOT NULL,
  `InHighOctets` bigint(255) NOT NULL,
  `OutHighOctets` bigint(255) NOT NULL,
  `InDiscards` bigint(255) NOT NULL,
  `OutDiscards` bigint(255) NOT NULL,
  `InErrors` bigint(255) NOT NULL,
  `OutErrors` bigint(255) NOT NULL,
  `Interface_id` int(10) unsigned NOT NULL,
  `Interface_host_id` mediumint(8) unsigned NOT NULL,
  PRIMARY KEY (`Interface_id`,`Interface_host_id`)
) ENGINE=MyISAM DEFAULT CHARSET=koi8r COMMENT='RRL Траффик\n';

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `Traff`
--
CREATE TABLE IF NOT EXISTS `Traff` (
`id` int(10) unsigned
,`Host_id` mediumint(8) unsigned
,`SNMP_date` date
,`SNMP_time` time
,`SNMP_unix_time` int(32)
,`IfSpeed` int(9)
,`TrafIn` decimal(62,0)
,`UtilIn` decimal(58,0)
,`TrafOut` decimal(62,0)
,`UtilOut` decimal(58,0)
,`InDiscards` bigint(255)
,`OutDiscards` bigint(255)
);
-- --------------------------------------------------------

--
-- Дублирующая структура для представления `Traff_group_by_day`
--
CREATE TABLE IF NOT EXISTS `Traff_group_by_day` (
`id` int(10) unsigned
,`host_id` mediumint(8) unsigned
,`snmp_date` date
,`max_trafIN_Mb` decimal(64,2)
,`avg_trafIN_Mb` decimal(60,2)
,`max_UtilIN_proc` decimal(58,0)
,`max_trafout_Mb` decimal(64,2)
,`avg_trafout_Mb` decimal(60,2)
,`max_Utilout_proc` decimal(58,0)
);
-- --------------------------------------------------------

--
-- Дублирующая структура для представления `Traf_group_day_full`
--
CREATE TABLE IF NOT EXISTS `Traf_group_day_full` (
`id` int(10) unsigned
,`host_id` mediumint(8) unsigned
,`snmp_date` date
,`max_trafIN_Mb` decimal(64,2)
,`avg_trafIN_Mb` decimal(60,2)
,`max_UtilIN_proc` decimal(58,0)
,`max_trafout_Mb` decimal(64,2)
,`avg_trafout_Mb` decimal(60,2)
,`max_Utilout_proc` decimal(58,0)
,`ifspeedMb` decimal(13,2)
,`hostname` varchar(150)
,`Ifname` varchar(45)
,`ifspeed` int(11)
,`ifDescr` varchar(100)
);
-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_metric`
--
CREATE TABLE IF NOT EXISTS `view_metric` (
`Metric` varchar(349)
,`SNMP_unix_time` int(32)
,`IFspeed` int(9)
,`interval_measure` int(32)
,`InHighOctets` bigint(255)
,`OutHighOctets` bigint(255)
,`InDiscards` bigint(255)
,`OutDiscards` bigint(255)
,`InErrors` bigint(255)
,`OutErrors` bigint(255)
);
-- --------------------------------------------------------

--
-- Дублирующая структура для представления `View_Metric_last10min`
--
CREATE TABLE IF NOT EXISTS `View_Metric_last10min` (
`Metric` varchar(349)
,`SNMP_unix_time` int(32)
,`IFspeed` int(9)
,`interval_measure` int(32)
,`InHighOctets` bigint(255)
,`OutHighOctets` bigint(255)
,`InDiscards` bigint(255)
,`OutDiscards` bigint(255)
,`InErrors` bigint(255)
,`OutErrors` bigint(255)
);
-- --------------------------------------------------------

--
-- Структура для представления `Traff`
--
DROP TABLE IF EXISTS `Traff`;

CREATE ALGORITHM=UNDEFINED DEFINER=`rost`@`192.168.100.214` SQL SECURITY DEFINER VIEW `Traff` AS select `a`.`Interface_id` AS `id`,`a`.`Interface_host_id` AS `Host_id`,`a`.`SNMP_date` AS `SNMP_date`,`a`.`SNMP_time` AS `SNMP_time`,`a`.`SNMP_unix_time` AS `SNMP_unix_time`,`a`.`IFspeed` AS `IfSpeed`,round(((`a`.`InHighOctets` * 8) / `a`.`interval_measure`),0) AS `TrafIn`,round(((((`a`.`InHighOctets` * 8) / `a`.`interval_measure`) / `a`.`IFspeed`) * 100),0) AS `UtilIn`,round(((`a`.`OutHighOctets` * 8) / `a`.`interval_measure`),0) AS `TrafOut`,round(((((`a`.`OutHighOctets` * 8) / `a`.`interval_measure`) / `a`.`IFspeed`) * 100),0) AS `UtilOut`,`a`.`InDiscards` AS `InDiscards`,`a`.`OutDiscards` AS `OutDiscards` from `SNMP-Traffic` `a`;

-- --------------------------------------------------------

--
-- Структура для представления `Traff_group_by_day`
--
DROP TABLE IF EXISTS `Traff_group_by_day`;

CREATE ALGORITHM=UNDEFINED DEFINER=`rost`@`192.168.100.214` SQL SECURITY DEFINER VIEW `Traff_group_by_day` AS select `a`.`id` AS `id`,`a`.`Host_id` AS `host_id`,`a`.`SNMP_date` AS `snmp_date`,round((max(`a`.`TrafIn`) / 1000000),2) AS `max_trafIN_Mb`,round((avg(`a`.`TrafIn`) / 1000000),2) AS `avg_trafIN_Mb`,max(`a`.`UtilIn`) AS `max_UtilIN_proc`,round((max(`a`.`TrafOut`) / 1000000),2) AS `max_trafout_Mb`,round((avg(`a`.`TrafOut`) / 1000000),2) AS `avg_trafout_Mb`,max(`a`.`UtilOut`) AS `max_Utilout_proc` from `Traff` `a` group by `a`.`SNMP_date`,`a`.`id`;

-- --------------------------------------------------------

--
-- Структура для представления `Traf_group_day_full`
--
DROP TABLE IF EXISTS `Traf_group_day_full`;

CREATE ALGORITHM=UNDEFINED DEFINER=`rost`@`192.168.100.214` SQL SECURITY DEFINER VIEW `Traf_group_day_full` AS select `a`.`id` AS `id`,`a`.`host_id` AS `host_id`,`a`.`snmp_date` AS `snmp_date`,`a`.`max_trafIN_Mb` AS `max_trafIN_Mb`,`a`.`avg_trafIN_Mb` AS `avg_trafIN_Mb`,`a`.`max_UtilIN_proc` AS `max_UtilIN_proc`,`a`.`max_trafout_Mb` AS `max_trafout_Mb`,`a`.`avg_trafout_Mb` AS `avg_trafout_Mb`,`a`.`max_Utilout_proc` AS `max_Utilout_proc`,round((`b`.`ifSpeed` / 1000000),2) AS `ifspeedMb`,`b`.`hostname` AS `hostname`,`b`.`IfName` AS `Ifname`,`b`.`ifSpeed` AS `ifspeed`,`b`.`ifDescr` AS `ifDescr` from (`Traff_group_by_day` `a` join `Interface` `b`) where (`a`.`id` = `b`.`id`);

-- --------------------------------------------------------

--
-- Структура для представления `view_metric`
--
DROP TABLE IF EXISTS `view_metric`;

CREATE ALGORITHM=UNDEFINED DEFINER=`rost`@`192.168.100.214` SQL SECURITY DEFINER VIEW `view_metric` AS select concat_ws('.',`c`.`description`,`b`.`IfTypeName`,concat('(',replace(`b`.`IfName`,'/','-'),')',`b`.`ifDescr`)) AS `Metric`,`a`.`SNMP_unix_time` AS `SNMP_unix_time`,`a`.`IFspeed` AS `IFspeed`,`a`.`interval_measure` AS `interval_measure`,`a`.`InHighOctets` AS `InHighOctets`,`a`.`OutHighOctets` AS `OutHighOctets`,`a`.`InDiscards` AS `InDiscards`,`a`.`OutDiscards` AS `OutDiscards`,`a`.`InErrors` AS `InErrors`,`a`.`OutErrors` AS `OutErrors` from ((`SNMP-Traffic` `a` join `Interface` `b`) join `host` `c`) where ((`a`.`Interface_id` = `b`.`id`) and (`a`.`Interface_host_id` = `c`.`id`) and (`c`.`description` like 'Yar%'));

-- --------------------------------------------------------

--
-- Структура для представления `View_Metric_last10min`
--
DROP TABLE IF EXISTS `View_Metric_last10min`;

CREATE ALGORITHM=UNDEFINED DEFINER=`rost`@`192.168.100.214` SQL SECURITY DEFINER VIEW `View_Metric_last10min` AS select concat_ws('.',`c`.`description`,`b`.`IfTypeName`,concat('<',replace(`b`.`IfName`,'/','-'),'>',`b`.`ifDescr`)) AS `Metric`,`a`.`SNMP_unix_time` AS `SNMP_unix_time`,`a`.`IFspeed` AS `IFspeed`,`a`.`interval_measure` AS `interval_measure`,`a`.`InHighOctets` AS `InHighOctets`,`a`.`OutHighOctets` AS `OutHighOctets`,`a`.`InDiscards` AS `InDiscards`,`a`.`OutDiscards` AS `OutDiscards`,`a`.`InErrors` AS `InErrors`,`a`.`OutErrors` AS `OutErrors` from ((`SNMP-Traffic` `a` join `Interface` `b`) join `host` `c`) where ((`a`.`Interface_id` = `b`.`id`) and (`a`.`Interface_host_id` = `c`.`id`) and (`c`.`description` like 'Yar-%') and ((unix_timestamp() - `a`.`SNMP_unix_time`) < 600));

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
