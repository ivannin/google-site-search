<?xml version="1.0" encoding="UTF-8" ?>
<!--
	Преобразование ответа GSS к HTML виду 
-->
<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:php="http://php.net/xsl">

	<xsl:output method="html" indent="yes" />

	<!-- Переменные под передаваемые параметры -->
	<xsl:variable name="paramQuery"></xsl:variable>
	<xsl:variable name="paramStart"></xsl:variable>
	<xsl:variable name="paramNumResults"></xsl:variable>
	<xsl:variable name="searchResultURL"></xsl:variable>
	<xsl:variable name="siteEncoding"></xsl:variable>
	
	<!-- Предварительные выборки результата -->
	<xsl:variable name="query" select="/GSP/Q" /> 
	<xsl:variable name="result" select="/GSP/RES" /> 
	<xsl:variable name="results" select="/GSP/RES/R" /> 
	<xsl:variable name="totalResults" select="/GSP/RES/M" />
	<xsl:variable name="resultsPerPage" select="/GSP/PARAM[@name='num']/@value" />
	<xsl:variable name="currentPageNo" select="floor($result/@SN div $resultsPerPage) + 1" />
	<xsl:variable name="suggest" select="/GSP/Spelling/Suggestion/@q" />
	
	<!-- Корневой шаблон -->
	<xsl:template match="/">
		<div class="searchResult">
			<h2>
				<xsl:text>Поиск: </xsl:text>
				<xsl:value-of select="$query" />
			</h2>
			<xsl:choose>
				<xsl:when test="$results">
					<xsl:call-template name="spellingSuggest" />
					<xsl:apply-templates select="$results" />
				</xsl:when>
				<xsl:otherwise>
					Результатов нет.
					<xsl:call-template name="spellingSuggest" />
				</xsl:otherwise>
			</xsl:choose>
			<!-- Вывод страниц -->
			<xsl:call-template name="paging" />
		</div>
	</xsl:template>	
	
	<!-- Шаблон вывода результата -->
	<xsl:template match="R">
		<!-- Элемент результата -->
		<div class="searchResultItem">
			<h4 class="title">
				<a href="{U}">
					<xsl:value-of select="T" disable-output-escaping="yes" />
				</a>
			</h4>
			<div class="snippet">
				<xsl:value-of select="S" disable-output-escaping="yes" />
			</div>
			<!-- Выводим URL или хлебные крошки -->
			<xsl:call-template name="showURL">
				<xsl:with-param name="url" select="U" />
				<xsl:with-param name="breadcrumbs" select="PageMap/DataObject[@type='breadcrumb']" />
			</xsl:call-template>
		</div>
	</xsl:template>

	<!-- Шаблон вывода исправленного запроса -->
	<xsl:template name="spellingSuggest">
		<xsl:if test="$suggest">
			<div class="spellingSuggest">
				<xsl:variable name="queryString" select="php:function('GSS::URLEndode',string($suggest),string($siteEncoding))" />
				<xsl:text>Возможно, Вы имели ввиду: </xsl:text>
				<a href="{$searchResultURL}?{$paramQuery}={$queryString}">
					<xsl:value-of select="$suggest" />
				</a>
			</div>			
		</xsl:if>
	</xsl:template>
	
	<!-- 
		Шаблон вывода URL или хлебных крошек
		Важное замечание! Google не очень корректно читает 
		свойство breadcrumb у объекта WebPage (http://schema.org/WebPage)
		поэтому настоятельно рекомендуется использовать http://data-vocabulary.org/Breadcrumb
		Особенность использования: передача URL для пользовательсовго поиска через доп.мета-свойство.
		Если ничего не получается, обратитесь к Ивану Никитину
		http://ivannikitin.com/services/seo/

	-->
	<xsl:template name="showURL">
		<xsl:param name="url" /><!-- URL страницы результата -->
		<xsl:param name="breadcrumbs" /><!-- Набор хлебных крошек -->
		<div class="url">
			<xsl:choose>
				<!-- Хлебные крошки переданы -->
				<xsl:when test="$breadcrumbs">
					<!-- Вывод хлебных крошек -->
					<xsl:for-each select="$breadcrumbs">
						<a href="{Attribute[@name='url']/@value}">
							<xsl:value-of select="Attribute[@name='title']/@value" />
						</a>
						<xsl:if test="position() != last()">
							<xsl:text> &gt; </xsl:text>
						</xsl:if>						
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<!-- Вывод просто URL -->
					<a href="{U}">
						<xsl:value-of select="U" />
					</a>
				</xsl:otherwise>
			</xsl:choose>		
		</div>
	</xsl:template>	
	
	<!-- Шаблон страниц с результатами поиска -->
	<xsl:template name="paging">
		<!-- Если результатов больше чем на одну страницу... -->
		<xsl:if test="$totalResults &gt; $resultsPerPage">
			<div class="paging">
				<xsl:variable name="pageCount" select="floor($totalResults div $resultsPerPage)" />
				<xsl:call-template name="page">
					<xsl:with-param name="count" select="$pageCount"/>
					<xsl:with-param name="queryString" select="php:function('GSS::URLEndode',string($query),string($siteEncoding))"/>
				</xsl:call-template>				
			</div>
		</xsl:if>
	</xsl:template>	
	
	<!-- Шаблон одной ссылки на страницу с результатами поиска -->
	<xsl:template name="page">
		<xsl:param name="i" select="1" />
		<xsl:param name="count" />
		<xsl:param name="queryString" />
		<!-- вывод ссылки на очередную страницу поиска -->
		<xsl:variable name="startFrom" select="(($i - 1) * $resultsPerPage)" />
		<a href="{$searchResultURL}?{$paramQuery}={$queryString}&amp;{$paramStart}={$startFrom}&amp;{$paramNumResults}={$resultsPerPage}">
			<xsl:if test="$currentPageNo = $i">
				<xsl:attribute name="class">current</xsl:attribute>
			</xsl:if> 
			<xsl:value-of select="$i" />
		</a>

		<xsl:if test="$i &lt; $count">
			<xsl:call-template name="page">
				<xsl:with-param name="i" select="$i + 1"/>
				<xsl:with-param name="count" select="$count"/>
				<xsl:with-param name="queryString" select="$queryString"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>	
	
</xsl:stylesheet>
