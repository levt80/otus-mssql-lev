/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

-- Вариант 1
select People.PersonID, People.FullName
from Application.People
where People.IsSalesperson = 1
  and People.PersonID not in (
    select SalespersonPersonID 
    from Sales.Invoices 
    where InvoiceDate = '2015-07-04')

-- Вариант 2
with sales as (
    select SalespersonPersonID 
    from Sales.Invoices 
    where InvoiceDate = '2015-07-04'
    )

select People.PersonID, People.FullName
from Application.People
left join sales on People.PersonID = sales.SalespersonPersonID
where People.IsSalesperson = 1
  and sales.SalespersonPersonID is null


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

-- Вариант 1-1
select i.StockItemID, i.StockItemName, mp.MinPrice
from [Warehouse].[StockItems] i
join (
    select stockitemid, min(unitPrice) as MinPrice
    from [Sales].[InvoiceLines]
    group by StockItemID
) as mp on i.StockItemID = mp.StockItemID
order by 1

-- Вариант 1-2
select 
    i.StockItemID, 
    i.StockItemName, 
    (
    select min(unitPrice)
    from [Sales].[InvoiceLines]
    group by StockItemID
    having StockItemID = i.StockItemID
    ) as MinPrice
from [Warehouse].[StockItems] i
order by 1

-- Вариант 2-1
with mp as (
    select StockItemID, min(unitPrice) as MinPrice
    from [Sales].[InvoiceLines]
    group by StockItemID
)

select i.StockItemID, i.StockItemName, mp.MinPrice
from [Warehouse].[StockItems] i
join mp on i.StockItemID = mp.StockItemID
order by 1

-- Вариант 2-2
with mp as (
    select 
        stockitemid, 
        min(unitPrice) as MinPrice
    from [Sales].[InvoiceLines]
    group by StockItemID
)

select 
    i.StockItemID, 
    i.StockItemName, 
    (
    select MinPrice
    from mp
    where StockItemID = i.StockItemID
    ) as MinPrice
from [Warehouse].[StockItems] i
order by 1

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

-- Вариант 1
select top 5 c.CustomerID, c.CustomerName, ct.TransactionAmount
from Sales.CustomerTransactions as ct
join [Sales].[Customers] as c on ct.CustomerID = c.CustomerID 
order by TransactionAmount desc

-- Вариант 2
select 
    c.CustomerID, 
    c.CustomerName,
    ct.TransactionAmount
from [Sales].[Customers] as c
join (
    select top 5 CustomerID, TransactionAmount
    from Sales.CustomerTransactions
    order by TransactionAmount desc
) as ct on c.CustomerID = ct.CustomerID

-- Вариант 3
with ct as (
    select top 5 CustomerID, TransactionAmount
    from Sales.CustomerTransactions
    order by TransactionAmount desc
    )

select 
    c.CustomerID, 
    c.CustomerName,
    ct.TransactionAmount
from [Sales].[Customers] as c
join ct on c.CustomerID = ct.CustomerID

-- Вариант 4
select top 5 
    ct.CustomerID, 
    ( select CustomerName 
      from [Sales].[Customers] 
      where CustomerID = ct.CustomerID
    ) as CustomerName,
    ct.TransactionAmount
from Sales.CustomerTransactions as ct
order by TransactionAmount desc

-- Вариант 5
with ct as (
    select top 5 CustomerID, TransactionAmount
    from Sales.CustomerTransactions
    order by TransactionAmount desc
    )

select top 5 
    ct.CustomerID, 
    ( select CustomerName 
      from [Sales].[Customers] 
      where CustomerID = ct.CustomerID
    ) as CustomerName,
    ct.TransactionAmount
from ct
order by TransactionAmount desc

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

select distinct 
    [Cities].CityID, 
    [Cities].CityName, 
    p.FullName 
from [Sales].[Invoices] i
join [Application].[People] p on i.PackedByPersonID = p.PersonID
join [Sales].[InvoiceLines] il on i.InvoiceID = il.InvoiceID
join [Sales].[Customers] on i.CustomerID = [Customers].CustomerID
join [Application].[Cities] on [Customers].DeliveryCityID = [Cities].CityID
where il.StockItemID in (
    select top 3 StockItemID
    from [Warehouse].[StockItems]
    order by UnitPrice desc)



-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

/*
Запрос выводит инвойс, дату инвйса, продавца, общую сумму инвойса и сумму принятых товаров
для инвойсов общей суммой свыше 27000
*/

-- Улучшение читабельности
with AggOrders as
(
    SELECT OrderLines.OrderId, SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) as TotalSummForPickedItems
	FROM Sales.OrderLines
    join Sales.Orders on OrderLines.OrderId = Orders.OrderId
         and Orders.PickingCompletedWhen IS NOT NULL
    group by OrderLines.OrderId
),
AggInvoices as (
    SELECT 
	    Invoices.InvoiceID, 
	    Invoices.InvoiceDate,
        Invoices.OrderId,
        Invoices.SalespersonPersonID,
        SUM(InvoiceLines.Quantity*InvoiceLines.UnitPrice) AS TotalSummByInvoice
    FROM Sales.Invoices 
    JOIN Sales.InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
    group by 
        Invoices.InvoiceID, 
	    Invoices.InvoiceDate,
        Invoices.OrderId,
        Invoices.SalespersonPersonID
    having SUM(InvoiceLines.Quantity*InvoiceLines.UnitPrice) > 27000
)

SELECT 
	InvoiceID, 
	InvoiceDate,
	People.FullName AS SalesPersonName,
    TotalSummByInvoice,
	TotalSummForPickedItems
FROM AggInvoices
join AggOrders on AggInvoices.OrderID = AggOrders.OrderID
join Application.People on People.PersonID = AggInvoices.SalespersonPersonID
ORDER BY TotalSummByInvoice DESC;

