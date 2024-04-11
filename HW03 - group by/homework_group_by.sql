/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
    year(InvoiceDate) as SaleYear,
    month(InvoiceDate) as SaleMonth,
    avg([UnitPrice]) as MeanPrice,
    sum(Quantity*UnitPrice) as TotalSale
from Sales.Invoices
join Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
Group by year(InvoiceDate), month(InvoiceDate)
order by SaleYear, SaleMonth

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
    year(InvoiceDate) as SaleYear,
    month(InvoiceDate) as SaleMonth,
    sum(Quantity*UnitPrice) as TotalSale
from Sales.Invoices
join Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
Group by year(InvoiceDate), month(InvoiceDate)
having sum(Quantity*UnitPrice) > 4600000
order by SaleYear, SaleMonth

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
    year(Invoices.InvoiceDate) as SaleYear,
    month(Invoices.InvoiceDate) as SaleMonth,
    [StockItems].[StockItemName],
    sum(InvoiceLines.Quantity*InvoiceLines.UnitPrice) as SaleSum,
    min(Invoices.InvoiceDate) as FirstSaleDate,
    sum(InvoiceLines.Quantity) as Quantity
from Sales.Invoices
join Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
join [Warehouse].[StockItems] on InvoiceLines.[StockItemID] = [StockItems].[StockItemID]
Group by 
    year(InvoiceDate), 
    month(InvoiceDate),
    [StockItems].[StockItemName]
having sum(InvoiceLines.Quantity) < 50
order by SaleYear, SaleMonth, [StockItemName]

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

select 
    cast(y.value as int) as [year],
    cast(m.value as int) as [month],
    isnull(s.TotalSale,0) as TotalSales
from (select value from STRING_SPLIT('2013,2014,2015,2016', ',')) as y
cross join (select value from STRING_SPLIT('1,2,3,4,5,6,7,8,9,10,11,12', ',')) as m
left join (
    select 
        year(InvoiceDate) as SaleYear,
        month(InvoiceDate) as SaleMonth,
        sum(Quantity*UnitPrice) as TotalSale
    from Sales.Invoices
    join Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
    Group by year(InvoiceDate), month(InvoiceDate)
    ) as s on y.value = s.SaleYear and m.value = s.SaleMonth
where s.TotalSale > 4600000 
    or s.TotalSale is null
order by [year], [month]

-- ---------------------------------------------------------------------------

select 
    cast(y.value as int) as [year],
    cast(m.value as int) as [month],
    i.[StockItemName],
    SaleSum,
    FirstSaleDate,
    isnull(s.Quantity,0) as Quantity
from (select value from STRING_SPLIT('2013,2014,2015,2016', ',')) as y
cross join (select value from STRING_SPLIT('1,2,3,4,5,6,7,8,9,10,11,12', ',')) as m
cross join (select [StockItemID], [StockItemName] from [Warehouse].[StockItems]) as i
left join (
    select 
        year(Invoices.InvoiceDate) as SaleYear,
        month(Invoices.InvoiceDate) as SaleMonth,
        [StockItems].[StockItemID],
        sum(InvoiceLines.Quantity*InvoiceLines.UnitPrice) as SaleSum,
        min(Invoices.InvoiceDate) as FirstSaleDate,
        sum(InvoiceLines.Quantity) as Quantity
    from Sales.Invoices
    join Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
    join [Warehouse].[StockItems] on InvoiceLines.[StockItemID] = [StockItems].[StockItemID]
    Group by 
        year(InvoiceDate), 
        month(InvoiceDate),
        [StockItems].[StockItemID]
    ) as s 
        on y.value = s.SaleYear 
        and m.value = s.SaleMonth
        and i.[StockItemID] = s.[StockItemID]
    where s.Quantity < 50
        or s.Quantity is null
    order by [year], [month], [StockItemName]

