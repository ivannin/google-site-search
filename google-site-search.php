<?php
/**
 * Класс обеспечивает работу с Google Site Search
 *
 * @author	Иван Никитин <ivan@nikitin.org>
 * @version  $Revision: 1.0 $
 * @access   public
 * @see      https://developers.google.com/custom-search/docs/xml_results?hl=en
 */
class GSS
{
/* ----------------- Константы и настройки GSS ----------------- */ 
	
	/**
	 * Параметр запроса поиска по умолчанию
	 * @static
	 */
	const PARAMETER_QUERY = 'q';		
	
	/**
	 * Параметр начальной позиции по умолчанию
	 * @static
	 */
	const PARAMETER_START = 's';

	/**
	 * Параметр количества результатов по умолчанию
	 * @static
	 */
	const PARAMETER_RESULTS = 'n';
	
	/**
	 * Кодировка UTF-8
	 * @static
	 */
	const UTF8 = 'UTF-8';	

	/**
	 * Кодировка CP-1251
	 * @static
	 */
	const CP1251 = 'windows-1251';
	
	/**
	 * Число результатов по умолчанию
	 * @static
	 */
	const N_RESULTS = 10;	
	
	/**
	 * C какого результата начинаем по умолчанию
	 * @static
	 */
	const OFFSET = 0;
	
	/**
	 * URL запроса
	 * @static
	 */
	const GOOGLE_URL = 'http://www.google.com/search?start=%1&num=%2&q=%3&ie=utf8&oe=utf8&client=google-csbe&output=xml_no_dtd&cx=%4';	
	
	/**
	 * Время хранения результатов в каше в секундах, сутки
	 * @static
	 */
	const CACHE_DEFAULT = 86400;	
	
	/**
	 * XSLT файл по умолчанию
	 * @static
	 */
	const XSL_FILE = 'google-site-search.xsl';	

	
/* -------------------------- Свойства ------------------------- */
	/**
	 * Идентификатор поисковой системы
	 * @var string
	 */
	public $cseID;
	
	/**
	 * Кодировка
	 * @var string
	 */
	public $encoding;	
	
	/**
	 * Путь к папке кэша
	 * @var string
	 */
	public $cacheFolder;		
	
	/**
	 * Путь к папке логов
	 * @var string
	 */
	public $logFolder;		

	/**
	 * Параметр запроса
	 * @var string
	 */
	public $queryParam;	

	/**
	 * Параметр начальной позиции
	 * @var string
	 */
	public $startParam;	

	/**
	 * Параметр числа результатов
	 * @var string
	 */
	public $numParam;

	/**
	 * Входной массив данных
	 * @var mixed
	 */
	public $input;	
	
	/**
	 * Время хранения результатов в кэше
	 * @var int
	 */
	public $cacheTime;	
	
	/**
	 * XSL файл
	 * @var string
	 */
	public $xslFile;		
	
	
/* --------------------------- Методы -------------------------- */	
	/**
	 * Консутруктор класса
	 *
	 * @param mixed $params	Параметры настройки класса: строка или аоосциативный массив
	 *	Если параметр строка, то это cseID - идентификатор поисковой системы, для получения ключа необходимо регистрация в http://www.google.ru/cse/
	 *	Если параметр массив, то это набор со следующими возможными значениями:
	 *		cseID		=> обязательно. идентификатор поисковой системы
	 *		cacheFolder => Путь к папке кэша, null, false или остуствие - кэш не используется
	 *		logFolder	=> Путь к папке логов, null, false или остуствие - лог не используется
	 *		encoding	=> Кодировка сайта
	 *		queryParam	=> имя параметра запроса в массиве данных, по умолчанию "q"
	 *		startParam	=> имя параметра с какого результата начитать, по умолчанию "s"
	 *		numParam	=> имя параметра сколько результатов выводить, по умолчанию "n"
	 *		input		=> входной массив данных, по умолчанию $_GET
	 *		cacheTime	=> время хранения результатов в кэше в секундах, по умолчанию сутки
	 *		xslFile		=> Файл таблицы преобразования XSL
	 */
	public function __construct($params)
	{
		
		// Если параметр строка, то это cseID
		if (is_string($params))
			$this->cseID = $params;
	
		// Читаем параметры
		$this->cseID = (isset($params['cseID'])) ? $params['cseID'] : $this->cseID;
		$this->cacheFolder = (isset($params['cacheFolder'])) ? $params['cacheFolder'] : FALSE;
		$this->logFolder = (isset($params['logFolder'])) ? $params['logFolder'] : FALSE;
		$this->encoding = (isset($params['encoding'])) ? $params['encoding'] : self::UTF8;
		$this->queryParam = (isset($params['queryParam'])) ? $params['queryParam'] : self::PARAMETER_QUERY;
		$this->startParam = (isset($params['startParam'])) ? $params['startParam'] : self::PARAMETER_START;
		$this->numParam = (isset($params['numParam'])) ? $params['numParam'] : self::PARAMETER_RESULTS;
		$this->input = (isset($params['input'])) ? $params['input'] : $_GET;
		$this->cacheTime = (isset($params['cacheTime'])) ? $params['cacheTime'] : self::CACHE_DEFAULT;
		$this->xslFile = (isset($params['xslFile'])) ? $params['xslFile'] : __DIR__ . '/' . self::XSL_FILE;

		$this->log(date('d.m.Y H:i:s') . ' Инициализация');
		$this->log('Начальные свойства: ' . var_export($this, TRUE));
		
		// Проверка обязательных или критичных параметров
		if (empty($this->cseID))
			throw new Exception('Parameter cseID must be specified!');
		if (!file_exists($this->xslFile))
			throw new Exception('XSL file ' . $this->xslFile . ' not found!');			
		
	}
	
	/**
	 * Деструктор класса
	 */	
	public function __destruct() 
	{
		$this->log('-------------------------------------');
	}
	
	/**
	 * Записывает в лог отладочное сообщение
	 *
	 * @param 	string 	$message	Строка вывода в лог
	 */
	protected function log($message)	
	{
		
		if (empty($this->logFolder)) return;
		$logFile = $this->logFolder . __CLASS__ . '.log';
		file_put_contents($logFile, $this->encode($message) . PHP_EOL, FILE_APPEND);
	}
	
	/**
	 * Функция кодирует строку в кодировку UTF-8 из кодировки, определенной настройкой
	 *
	 * @param 	string 	$string	Входная строка
	 * @return	string
	 */
	protected function decode($string)	
	{
		return ($this->encoding == self::UTF8) ? $string : iconv($this->encoding, self::UTF8, $string);
	}	
	/**
	 * Функция кодирует строку из кодировки UTF-8 в кодировку, определенную настройкой
	 *
	 * @param 	string 	$string	Входная строка
	 * @return	string
	 */
	protected function encode($string)	
	{
		return ($this->encoding == self::UTF8) ? $string : iconv(self::UTF8, $this->encoding, $string);
	}	
	
	/**
	 * Запрос
	 * @param 	string 	$queryString	Входная строка, если нет берется из входного массива	 
	 */	
	public function query($queryString='') 
	{
		// Читаем параметры
		// Строка запроса
		if (empty($queryString))
			$queryString = (isset($this->input[$this->queryParam])) ? 
				trim(strip_tags($this->decode($this->input[$this->queryParam]))) : 
				'';
		else
			$queryString = $this->decode($queryString);
		$this->log('Строка запроса: ' . $queryString);
		
		// Если строки запроса нет, возвращаем FALSE
		if (empty($queryString)) 
			return FALSE;
		
		// Число параметров
		$nResults =(isset($this->input[$this->numParam])) ? 
			(int) $this->input[$this->numParam] : 
			self::N_RESULTS;
		
		// Начало
		$offset = (isset($this->input[$this->startParam])) ?
			$this->input[$this->startParam] :
			self::OFFSET;
		
		// Получаем результаты	
		$result = $this->getXMLResult($queryString, $nResults, $offset);
		// Готовим XSL таблицу
		$xsl = $this->getXSL();
		// XSLT преобразование
		$xslt = new XSLTProcessor;
		$xslt->registerPHPFunctions();
		$xslt->importStyleSheet($xsl);
		$html = $xslt->transformToXML($result);
		// Результат
		return $this->encode($html);
	}	
	
	/**
	 * Загружает XML DOMDocument с результатами поиска
	 * @param string 	$queryString	Строка запроса	 
	 * @param int 		$nResults		Число результатов	 
	 * @param int		$offset			С какого результата начинаем	 
	 * @return DOMDocument 	Объект DOM	 
	 */	
	public function getXMLResult($queryString, $nResults, $offset) 
	{
		// Строка, характеризуюзая поиск
		$queryID = $queryString. ':' . $nResults . ':' . $offset;
		$this->log('queryID: ' . $queryID);
		
		// Файл кэша
		$cacheFile = (!empty($this->cacheFolder)) ?
			$this->cacheFolder . md5($queryID) . '.xml' :
			FALSE;
			
		// Результат	
		$result = new DOMDocument();
		
		// Провека данных в кэше
		if ($cacheFile && file_exists($cacheFile))
		{
			// Проверка времени кэша
			if (filemtime($cacheFile) >= time() - $this->cacheTime)
			{
				// Читаем данные из кэша
				$this->log('Чтение данных из кэша: ' . $cacheFile);
				$result->load($cacheFile);
				return $result;
			}
		}
		
		// Вставка параметров в запрос
		$url = str_replace(
			array('%1', '%2', '%3', '%4'),
			array($offset,  $nResults, urlencode($queryString), $this->cseID),
			self::GOOGLE_URL);
			
		$this->log('URL запроса: ' . $url);	
		
		// Контекст загрузки
		$opts = array(
			'http'	=>	array(
				'method'	=>	'GET',
				'header'	=>	'Accept-language: ru'
			)
		);
		$context = stream_context_create($opts);
		libxml_set_streams_context($context);
		// Загрузка результатов
		$result->load($url);
		
		// Записываем строку для отладки
		$result->insertBefore($result->createComment($queryID), $result->documentElement);
		
		// Запись данных в кэш
		if ($cacheFile)
		{
			$this->log('Запись в кэш: ' . $cacheFile);
			$result->save($cacheFile);
		}
		
		// возвращаем результат:
		return $result;
	}	
	
	
	/**
	 * Загружает и подготавливает DOMDocument с таблицей XSLT
	 * @return DOMDocument 	Объект DOM	 
	 */	
	public function getXSL() 
	{
		$this->log('Загрузка XSL: ' . $this->xslFile);
		$xsl = new DOMDocument;
		$xsl->load($this->xslFile);	
		
		// Передача параметров в преобразование
		$this->setParameterXSLT($xsl, 'paramQuery', $this->queryParam);
		$this->setParameterXSLT($xsl, 'paramStart', $this->startParam);
		$this->setParameterXSLT($xsl, 'paramNumResults', $this->numParam);
		$this->setParameterXSLT($xsl, 'searchResultURL', $_SERVER['PHP_SELF']);
		$this->setParameterXSLT($xsl, 'siteEncoding', $this->encoding);
		
		return $xsl;
		
	}
	
	
	
	/**
	 * Передает параметр в XSLT документ
	 *
	 * @param 	DomDocument	$xslt 	DOM XSLT
	 * @param 	string 		$var 	Имя переменной в XSLT
	 * @param 	string 		$value 	Значение переменной
	 */
	protected function setParameterXSLT(&$xslt, $var, $value)
	{
		$xp = new DOMXPath($xslt);
		$xp->registerNamespace('xsl', 'http://www.w3.org/1999/XSL/Transform');
		// Находим переменную
		$xpath = "/xsl:stylesheet/xsl:variable[@name='$var']";
		$nodes = $xp->query($xpath);
		foreach ($nodes as $node) 
		{
			// убираем все вложенные узлы
			while ($node->hasChildNodes())
				$node->removeChild($node->lastChild);
			// Создаем новый текстовый узел
			$nodeValue = $xslt->createTextNode($value);
			// Добавляем его в узел переменой
			$node->appendChild($nodeValue);
		}		
	}

	/**
	 * Сервисная функция, вызывается из XSLT для кодирования запроса в URL
	 *
	 * @static
	 * @param string	$string		Строка для коддирования
	 * @param string	$encoding	кодировка
	 */
	static function URLEndode($string, $encoding)
	{
		if ($encoding != self::UTF8)
			$string = iconv(self::UTF8, $encoding, $string);
		return urlencode($string);
	}
	
}
?>