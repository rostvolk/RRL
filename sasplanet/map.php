<?php
// ---------------------------------------------------------------------------
// Формирует растровый слой с отображением объектов kml
// а также заказов, с которыми ведется работа
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Глобальные переменные
// ---------------------------------------------------------------------------

$tilesize = 256; // размер тайла
$iconsize = 16; // размер иконки
$iconscale = 1; // масштабирование иконки
$iconhalfsize = floor($iconsize * $iconscale / 2);
$offsetx = $iconhalfsize + 2; // смещение по x от точки до подписи
$maxoffsety = 6 * $iconscale; // макс. смещение по у от точки до подписи
$gapwidth = 2; // промежуток между надписью и краем картинки

$bcolors = array(
	array(0xff, 0x99, 0xcc),
	array(0xff, 0xcc, 0x99),
	array(0xff, 0xff, 0x99),
	array(0xcc, 0xff, 0xcc),
	array(0x99, 0xcc, 0xff)
);

$fcolors = array(
	array(0x00, 0x00, 0xff),
	array(0x00, 0x80, 0x00),
	array(0x80, 0x00, 0x80),
	array(0x00, 0x00, 0x00)
);

// ---------------------------------------------------------------------------
// Описание функций
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
function checkicon($sIconName) {
	if (file_exists(trim($sIconName))) {
		return trim($sIconName);
	}
	return 'noicon.png';
}

// ---------------------------------------------------------------------------
function gettotallabel($x1, $y1, $x2, $y2) {
	// много точек
	$query = "
	SELECT
		count(*) AS kolvo
	FROM
		points
	WHERE
		$x1 <= x
		AND x < $x2
		AND $y1 <= y
		AND y < $y2
		AND	comment <> ''";
	$result = my_mysql_query($query);
	$row = mysql_fetch_assoc($result);

	$arr = array();
	if ($row['kolvo'] > 0) {
		$arr[] = array('text' =>"{$row['kolvo']} комментариев",
						'bcolor' => array(255, 255, 255),
						'fcolor' => array(255, 0, 0));
	}
	return $arr;
}

// ---------------------------------------------------------------------------
function compositelabel($labels, $font, $size, $bordersize) {
	// создает картинку из нескольких надписей
	// $labels[0...n-1] - массив, каждый из элементов которого
	// есть тоже массив:
	//	text: текст, который надо вывести
	//	bcolor - цвет фона ('r', 'g', 'b')
	//	fcolor - цвет текста
	// $font, $size - шрифт и его размер
	// $border - дополнительный краешек вокруг текста
	$size=8;
	$boxes = array();
	$totalheight = 2 * count($labels) * ($bordersize + 1); // высота картинки
	 // (ширина бортиков)
	$totalwidth = 0;
	for ($i = 0; $i < count($labels); $i++) {
		$box = imagettfbbox($size, 0, $font, $labels[$i]['text']);
		$boxes[$i] = $box;
		$totalheight = $totalheight + ($box[1] - $box[5] + 1); // высота в пикселях
		$totalwidth = max($totalwidth, ($box[2] - $box[0] + 1)); // ширина в пикселях
	}
	$totalwidth = $totalwidth + 2 * ($bordersize + 1);
	
	$im = imagecreatetruecolor($totalwidth, $totalheight);
	imageantialias($im, false);

	$y = 0; // реальная координата начала вывода текста
	for ($i = 0; $i < count($labels); $i++) {
		$label = $labels[$i];
		$bcolor3 = $label['bcolor'];
		$bcolor = imagecolorallocate($im, $bcolor3[0], $bcolor3[1], $bcolor3[2]);
		$fcolor3 = $label['fcolor'];
		$fcolor = imagecolorallocate($im, $fcolor3[0], $fcolor3[1], $fcolor3[2]);

		$box = $boxes[$i];
		$textheight = $box[1] - $box[5] + 1; // высота в пикселях
		$textwidth = $box[2] - $box[0] + 1; // ширина в пикселях

		imagefilledrectangle($im, 1, $y + 1,
			$totalwidth - 2, $y + $bordersize * 2 + $textheight, $bcolor);
		imagerectangle($im, 0, $y,
			$totalwidth - 1, $y + $bordersize * 2 + $textheight + 1, $fcolor);
		imagettftext($im, $size, 0, $bordersize - $box[6] + 1, $y + $bordersize - $box[7] + 1,
			$fcolor, $font, $label['text']);

		$y = $y + $textheight + ($bordersize + 1) * 2;
	}
	return $im;
}

// ---------------------------------------------------------------------------
function placeincenter($im, $arr, $font) {
	if (count($arr) == 0)
		return;
	$tilesize = imagesx($im);
	$imlab = compositelabel($arr, $font, 10, 2);
	$imlabx = imagesx($imlab);
	$imlaby = imagesy($imlab);
	imagecopy($im, $imlab, floor($tilesize/2)-floor($imlabx/2),
			floor($tilesize/2)-floor($imlaby/2), 0, 0, $imlabx, $imlaby);
	imagedestroy($imlab);
	$color1 = imagecolorallocate($im, 128, 128, 128);
	imagerectangle($im, 3, 3, $tilesize-4, $tilesize-4,$color1);
}

function circle($centrx,$centry,$rad){
	$str=" ";
	$rad=$rad*0.0001;
	$angl = 0;
	while ($angl <=6.29 ) {
		$x1=round(cos($angl)*$rad+$centrx,8);
		$y1=round(sin($angl)*$rad*0.7+$centry,8);	
		$str=$str."$x1,$y1,0 ";
   	  $angl=$angl+6.28318/24 ;  
	}

	return $str;
}

// ---------------------------------------------------------------------------
// Основная программа
// ---------------------------------------------------------------------------

if (!array_key_exists('box', $_GET)) {
	die ("No parameter box");
}

if (!array_key_exists('t', $_GET)) {
	die ("No parameter t");
}

if (!array_key_exists('z', $_GET)) {
	die ("No parameter z");
}

include("config.inc.php");

// запишем данные в таблички
$x = 0+$_GET['x'];
$y = 0+$_GET['y'];
$z = 0+$_GET['z'];

// имя клиента
if (array_key_exists('client', $_GET))
	$client = $_GET['client'];
else
	$client = $_SERVER['REMOTE_ADDR'];

date_default_timezone_set('Europe/Kiev');
$cur_time = time();

$query = "
REPLACE INTO
	settings
SET
	client = '$client',
	lastx = $x,
	lasty = $y,
	lastzoom = $z,
	lastaccess = $cur_time";
my_mysql_query($query);
 
// а теперь начинаем рисовать картиночки
list($x1, $y1, $x2, $y2) = explode(',', $_GET['box']);
$x1 = 0 + $x1;
$x2 = 0 + $x2;
$y1 = 0 + $y1;
$y2 = 0 + $y2;

$t = $_GET['t']; // png или kml

if ($t == 'png') {
	$im = imagecreatetruecolor(256,256);
	imagealphablending($im, false);
	$transparent = imagecolorallocatealpha($im, 255,255,255,127);
	imagefill($im, 0, 0, $transparent);
        imagealphablending($im,true);
	$black = imagecolorallocate($im, 0, 0, 0);
	$white = imagecolorallocate($im, 255, 255, 255);
	$font = "arial.ttf";
	$header = "Content-type: image/png";
	$labels = array();
}
else {
	$kml_beg = 
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<kml xmlns=\"http://earth.google.com/kml/2.0\">
<Document>
";
	$kml_end = 
"</Document>
</kml>
";
	$kml = "";
	$header = "Content-Type: application/vnd.google-earth.kml+xml";
}

// выберем все точки, подлежащие выводу
$query = "
SELECT
	id,
	x,
	y,
	description,
	icon,
	comment,
	colorgroup
FROM
	points
WHERE
	$x1 <= x
	AND x < $x2
	AND $y1 <= y
	AND y < $y2
ORDER BY
	y,
	x";
$result = my_mysql_query($query);
$num_points = mysql_num_rows($result);

$showLabels = false;
if ($num_points > 40) {
	
	if ($t == 'png') {
		$arr = gettotallabel($x1, $y1, $x2, $y2);
		$arr[] = array('text' =>"$num_points объектов",
						'bcolor' => array(224, 224, 224),
						'fcolor' => array(160, 0, 160));
		placeincenter($im, $arr, $font);
	}
	else {
		// kml - ничего делать не надо
	}
}

else if ($num_points > 0) {
	$icoArray = array();
	while ($row = mysql_fetch_assoc($result)) {
		// координаты точки на рисунке -----------------------------------
		$px = floor($tilesize * ($row['x'] - $x1) / ($x2 - $x1));
		$py = $tilesize - 1 - floor($tilesize * ($row['y'] - $y1) / ($y2 - $y1));

		// выведем иконку ------------------------------------------------
		$ix = max($px - $iconhalfsize, 0);
		$ix = min($ix, $tilesize - $iconsize * $iconscale);

		// размещение иконки над точкой
		$iy = $py - $iconsize * $iconscale + 1;
		if ($iy < 0)
			$iy = $iy + $iconsize * $iconscale;

		if ($t == 'png') {
			$icon = imagecreatefrompng(checkicon($row['icon']));
			if ($row['comment'] == '')
				imagegammacorrect ($icon, 1.0, 1.7);
			imagecopyresampled($im, $icon, $ix, $iy, 0, 0, $iconsize * $iconscale, $iconsize * $iconscale, $iconsize, $iconsize);
			imagedestroy($icon);

			if ($row['comment'] <> '') {
				// метка точки
				$colors = getcolors($row['colorgroup']);
				$arr = array();
				$arr[] = array('text' => $row['comment'],
								'bcolor' => $colors['back'],
								'fcolor' => $colors['front']
								);
				$row['text'] = $arr;

				// положение точки
				$row['px'] = $ix + $iconhalfsize;
				$row['py'] = $iy + $iconhalfsize;

				$icoArray[$row['id']] = $row; 
			}
		}
		else {
			// ----------------------------------------------------


			$kmladd = circle($row['x'],$row['y'],10);

			$descr = "<img src=\"http://{$_SERVER['SERVER_NAME']}/".checkicon($row['icon'])."\"> {$row['description']}";
			if ($row['comment'] <> '')
				$descr = $descr."<br><b>{$row['comment']}</b><br>";
			$descr = $descr."<br><br>
<a href=\"http://{$_SERVER['SERVER_NAME']}/editpoint.php?id={$row['id']}\">
<img src=\"http://{$_SERVER['SERVER_NAME']}/edit.png\" border=\"0\"></a>
 <a href=\"http://{$_SERVER['SERVER_NAME']}/updatepoint.php?id={$row['id']}&delete=1\">
<img src=\"http://{$_SERVER['SERVER_NAME']}/delete.png\" border=\"0\"></a>
<img src=\"http://{$_SERVER['SERVER_NAME']}/warning.png\">";
			$kml = $kml."
<Placemark>
	 <description>
		<![CDATA[{$descr}]]>
	 </description>
	   <MultiGeometry>
	     <LineString>
  		<coordinates>".$kmladd."
	     </coordinates> 
  	    </LineString>
	
	<Point>
	  <coordinates>{$row['x']},{$row['y']},0</coordinates>
	 </Point>
	</MultiGeometry>
  </Placemark>
";
			// ----------------------------------------------------	
		}


	} // end while (цикл перебора точек) и создания массива меток
 
	if ($t == 'png') {
		$num_comments = count($icoArray);
 		if ($num_comments <= 10) {
			$labels = array();
			foreach ($icoArray as $label) {
				if (array_key_exists('text', $label)) {
					$box = compositelabel($label['text'], $font, 10, 2);
					$labelwidth = imagesx($box); // ширина в пикселях
					$labelheight = imagesy($box); // высота в пикселях

					// разместим по оси х
					// если точка - в левой части картинки, то надпись - справа
					if ($label['px'] < 128) {
						$labelx1 = $label['px'] + $offsetx + 1;
						$labelx2 = $labelx1 + $offsetx + $labelwidth;
					}
					else {
						$labelx1 = $label['px'] - $offsetx - $labelwidth;
						$labelx2 = $label['px'] - $offsetx - 1;
					}
					
					// разместим по оси y
					$labely1 = max($label['py'] - floor($labelheight/2), 0);
					$labely2 = $labely1 + $labelheight-1;

					if ($labely2 >= $tilesize - 1) {
						// слишком низко
						$labely2 = $tilesize - 2;
						$labely1 = $labely2 - $labelheight + 1;
					}

					// координаты определены
					$labels[] = array('x1' => $labelx1, 'y1' => $labely1, 'x2' => $labelx2, 'y2' => $labely2, 'w' => $labelwidth, 'h' => $labelheight, 'image' => $box);
				}
			}

			// это - непосредственно показ меток
			$count = count($labels);

			// теперь выводим метки
			for ($i = 0; $i < $count; $i++) {
				$label = $labels[$i];
				imagecopy($im, $label['image'], $label['x1'], $label['y1'],
							0, 0, $label['w'], $label['h']);
				imagedestroy($label['image']);
			}
		}
		else {
			// надписей слишком много.
			// выведем одну большую
			$arr = array();
			$arr[] = array('text' =>"$num_comments комментариев",
							'bcolor' => array(255, 255, 255),
							'fcolor' => array(255, 0, 0));
			placeincenter($im, $arr, $font);
		}

	}
	else {
		// kml - ничего делать не надо
	}

} // end if (число точек на картинке позволяет их вывести)

header($header);
if ($t == 'png') {
	imagealphablending($im,false);
	imagesavealpha($im,true);
	imagepng($im);
	imagedestroy($im);
}
else {
	$kml = $kml_beg.$kml.$kml_end;
	echo $kml;
}
?>
