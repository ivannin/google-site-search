Мой вариант Google Site Search
Данный код реализует работу поиска на сайте средствами Google Site Search.

## Начало работы

Данный код использует ПЛАНТУЮ ВЕРСИЮ Googlу Site Search. Для начала необходимо зарегистрироваться на сайте http://www.google.com/sitesearch

После регистрации необходимо перейти в раздел настройка и нажать кнопку [Идентификатор поисковой системы] http://www.google.ru/cse/setup/basic Запишите полученный идентификатор

## Использование

Подключите к своей странице файл google-site-search.php с помощью функции require() На самой странице поиска впишите следующий код:
```php
require($_SERVER["DOCUMENT_ROOT"]."/search/gss/google-site-search.php"); 
$search = new GSS(array( 
  'cseID' => '010715444785431631581:ec-hohtyejs', 
  'cacheFolder' => $_SERVER["DOCUMENT_ROOT"].'/../cache/', 
  'logFolder' => FALSE, 
  'encoding' => 'windows-1251', 
  )); 
echo $search->query();
```

Ассоциативный массив с параметрами может принимать следующие значения:

* cseID => обязательно. идентификатор поисковой системы
* cacheFolder => Путь к папке кэша, null, false или остуствие - кэш не используется
* logFolder => Путь к папке логов, null, false или остуствие - лог не используется
* encoding => Кодировка сайта, по умолчанию UTF-8
* queryParam => имя параметра запроса в массиве данных, по умолчанию "q"
* startParam => имя параметра с какого результата начитать, по умолчанию "s"
* numParam => имя параметра сколько результатов выводить, по умолчанию "n"
* input => входной массив данных, по умолчанию $_GET
* cacheTime => время хранения результатов в кэше в секундах, по умолчанию сутки
* xslFile => Файл таблицы преобразования XSL

###Особенности

Для формирования вывода используется XSLT. Стандартный пример такого преобразования google-site-search.xsl. Пример использования вывода с микроваданными schema.org в файле gabris-sample.xsl. Это работающий пример с сайта http://www.gabris.ru
