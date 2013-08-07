<?xml version="1.0" encoding="UTF-8" ?>
<!--
	Вывод результатов поиска с разметкой schema.org на сайте white-cat.ru 
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
			<xsl:attribute name="data-search-result"><xsl:value-of select="@N" /></xsl:attribute>
			<!-- Выводим фотографию -->
			<xsl:call-template name="showPhoto">
				<xsl:with-param name="url" select="U" />
				<xsl:with-param name="current" select="." />
			</xsl:call-template>
			<div class="snippet">			
				<h4 class="title">
					<a href="{U}">
						<xsl:value-of select="T" disable-output-escaping="yes" />
						<!-- Выводим цены 
						<xsl:call-template name="showPrices">
							<xsl:with-param name="url" select="U" />
							<xsl:with-param name="current" select="." />
							<xsl:with-param name="tag">span</xsl:with-param>
							<xsl:with-param name="text"> — </xsl:with-param>
						</xsl:call-template> -->						
					</a>
				</h4>
				<!-- Выводим сниппет -->
				<p><xsl:value-of select="S" disable-output-escaping="yes" /></p>
				<!-- Выводим цены -->
				<xsl:call-template name="showPrices">
					<xsl:with-param name="url" select="U" />
					<xsl:with-param name="current" select="." />
					<xsl:with-param name="text">Цена: </xsl:with-param>
				</xsl:call-template>	
				<!-- Выводим наличие товаров -->
				<xsl:call-template name="showAvailability">
					<xsl:with-param name="url" select="U" />
					<xsl:with-param name="current" select="." />
				</xsl:call-template>
				<!-- Выводим URL или хлебные крошки -->
				<xsl:call-template name="showURL">
					<xsl:with-param name="url" select="U" />
					<xsl:with-param name="breadcrumbs" select="PageMap/DataObject[@type='breadcrumb']" />
				</xsl:call-template>				
			</div>
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
		<xsl:variable name="maxPageCount" select="10" />
		<!-- вывод ссылки на очередную страницу поиска -->
		<xsl:variable name="startFrom" select="(($i - 1) * $resultsPerPage)" />
		<a href="{$searchResultURL}?{$paramQuery}={$queryString}&amp;{$paramStart}={$startFrom}&amp;{$paramNumResults}={$resultsPerPage}">
			<xsl:if test="$currentPageNo = $i">
				<xsl:attribute name="class">current</xsl:attribute>
			</xsl:if> 
			<xsl:value-of select="$i" />
		</a>
		<xsl:if test="($i &lt; $count and $i &lt; $maxPageCount)">
			<xsl:call-template name="page">
				<xsl:with-param name="i" select="$i + 1"/>
				<xsl:with-param name="count" select="$count"/>
				<xsl:with-param name="queryString" select="$queryString"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>	
	
	<!-- Шаблон вывода фотографий резульатов -->
	<xsl:template name="showPhoto">
		<xsl:param name="url" /><!-- URL результата -->
		<xsl:param name="current" /><!-- Текущий элемент поиска-->
		<!-- Берем первую фотографию -->
		<xsl:variable name="image" select="$current/PageMap/DataObject[@type='product']/Attribute[@name='image']/@value[1]" />
		<div class="photo"> 
			<xsl:if test="$image">
				<xsl:attribute name="style">background-image:url('/cms/_tpl/lib/resizer.php?url=<xsl:value-of select="$image" />&amp;w=70&amp;h=110')</xsl:attribute>
			</xsl:if>
			<xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
		</div>
	</xsl:template>

	<!-- Шаблон вывода цены -->
	<xsl:template name="showPrices">
		<xsl:param name="url" /><!-- URL результата -->
		<xsl:param name="current" /><!-- Текущий элемент поиска-->
		<xsl:param name="tag">div</xsl:param><!-- Каким тегом обрамить результат -->
		<xsl:param name="text" /><!-- Текст перед выводом цены -->
		<!-- Выберем все цены-->
		<xsl:variable name="prices" select="$current/PageMap/DataObject[@type='offer']/Attribute[@name='price']/@value" />
		<xsl:if test="$prices">
			<!-- Минимальная цена -->
			<xsl:variable name="minPrice">
			   <xsl:for-each select="$prices">
				  <xsl:sort data-type="number" order="ascending"/>
				  <xsl:if test="position() = 1"><xsl:value-of select="."/></xsl:if>
			   </xsl:for-each>
			</xsl:variable>

			<!-- Максимальная цена -->
			<xsl:variable name="maxPrice">
			   <xsl:for-each select="$prices">
				  <xsl:sort data-type="number" order="descending"/>
				  <xsl:if test="position() = 1"><xsl:value-of select="."/></xsl:if>
			   </xsl:for-each>
			</xsl:variable>		
			
			<!-- Вывод -->
			<xsl:element name="{$tag}">
				<xsl:attribute name="class">price</xsl:attribute>
				<xsl:if test="$text">
					<xsl:value-of select="$text" />
				</xsl:if>
				<xsl:choose>
					<!-- Несколько цен и они различаются -->
					<xsl:when test="$minPrice != $maxPrice">
						<xsl:value-of select="$minPrice" />
						<xsl:text> ... </xsl:text>
						<xsl:value-of select="$maxPrice" />
						<xsl:text> руб.</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$maxPrice" />
						<xsl:text> руб.</xsl:text>
					</xsl:otherwise>
				</xsl:choose>			
			</xsl:element>
		</xsl:if>
	</xsl:template>

	<!-- Шаблон вывода наличия товаров -->
	<xsl:template name="showAvailability">
		<xsl:param name="url" /><!-- URL результата -->
		<xsl:param name="current" /><!-- Текущий элемент поиска-->
		<!-- Находим предложения, которые в наличии -->
		<xsl:variable name="availabilityOffers" select="$current/PageMap/DataObject[@type='offer']/Attribute[@name='availability' and @value='in_stock']/.." />
		<xsl:if test="count($availabilityOffers) &gt; 0">
			<p>В наличии</p>
		</xsl:if>
	</xsl:template>
	
</xsl:stylesheet>
