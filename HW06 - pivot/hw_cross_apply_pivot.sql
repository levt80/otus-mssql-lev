/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

select
    format(InvoiceMon,'dd.MM.yyyy') as InvoiceMonth,
    [Gasport, NY],
    [Jessie, ND],
    [Medicine Lodge, KS],
    [Peeples Valley, AZ],
    [Sylvanite, MT]
from (
    select
        InvoiceMon = DATETRUNC(month,[Invoices].InvoiceDate),
        ClientName = substring([Customers].CustomerName, CHARINDEX('(',[Customers].CustomerName)+1, CHARINDEX(')',[Customers].CustomerName)-CHARINDEX('(',[Customers].CustomerName)-1),
        PurchaseQuantity = [InvoiceLines].Quantity
    from [Sales].[Invoices]
    join [Sales].[InvoiceLines] on [Invoices].InvoiceID = [InvoiceLines].InvoiceID
    join [Sales].[Customers] on [Invoices].CustomerID = [Customers].CustomerID
    where [Invoices].CustomerID between 2 and 6
    ) as PivotSource
pivot
    (
    sum(PurchaseQuantity)
    for
    ClientName in (
        [Gasport, NY],
        [Jessie, ND],
        [Medicine Lodge, KS],
        [Peeples Valley, AZ],
        [Sylvanite, MT]
        )
    ) as report
order by InvoiceMon

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select
    CustomerName,
    AddressLine
from (
    select
        [CustomerName],
        [DeliveryAddressLine1],
        [DeliveryAddressLine2],
        [PostalAddressLine1],
        [PostalAddressLine2]
    from [Sales].[Customers]
    where [CustomerName] like '%Tailspin Toys%'
    ) as UnpivotSource
unpivot (AddressLine
    for AddressType
    in (
        [DeliveryAddressLine1],
        [DeliveryAddressLine2],
        [PostalAddressLine1],
        [PostalAddressLine2]
        )
) as result


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select CountryId, CountryName, Code
from (
    select 
        CountryId, 
        CountryName, 
        IsoAlpha3Code, 
        cast(IsoNumericCode as nvarchar(3)) as NumericCode
    from Application.Countries
) as UnpivotSource
unpivot (
    Code
    for Cod in (
        IsoAlpha3Code,
        NumericCode
        )
) as result

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select
    c.CustomerID, 
    c.CustomerName,
    oa.StockItemID,
    oa.MaxPrice,
    oa.LastDate
from [Sales].[Customers] as c
outer apply (
    select top 2
        lt.CustomerID, 
        lt.StockItemID,
        lt.MaxPrice,
        rt.LastDate
    from (
        select 
            [Invoices].CustomerID,
            [InvoiceLines].StockItemID,
            (   select max(il.UnitPrice) 
                from [Sales].[Invoices] as i 
                join [Sales].[InvoiceLines] il on i.InvoiceID = il.InvoiceID 
                where i.CustomerID = [Invoices].CustomerID 
                and il.StockItemID = [InvoiceLines].StockItemID
            ) as MaxPrice
        from [Sales].[Invoices] 
        join [Sales].[InvoiceLines] on [Invoices].InvoiceID = [InvoiceLines].InvoiceID
        group by [Invoices].CustomerID,
            [InvoiceLines].StockItemID
        ) as lt
    cross apply (
        select
            max(i.InvoiceDate) as LastDate
        from [Sales].[Invoices] as i
        join [Sales].[InvoiceLines] as il on i.InvoiceID = il.InvoiceID
        where i.CustomerID = lt.CustomerID
            and il.StockItemID = lt.StockItemID
            and il.UnitPrice = lt.MaxPrice
        group by i.CustomerID,
            il.StockItemID
        ) as rt
    where lt.CustomerID = c.CustomerID
    order by CustomerID, MaxPrice desc
    ) as oa

