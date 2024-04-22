/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

with sales as (
    select 
        Invoices.InvoiceDate as [Дата продажи], 
        sum(InvoiceLines.Quantity*InvoiceLines.UnitPrice) as [Сумма Продажи]
    from Sales.Invoices
    join Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
    where Invoices.InvoiceDate >= '2015-01-01'
    group by Invoices.InvoiceDate
)
select 
    [Дата продажи], 
    (select sum([Сумма Продажи]) from sales as s1 where month(s.[Дата продажи]) = month(s1.[Дата продажи])) as [Нарастающий итог по месяцу]
from sales as s
order by 1;

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

select 
    Invoices.InvoiceDate as [Дата продажи], 
    sum(sum(InvoiceLines.Quantity*InvoiceLines.UnitPrice)) over (partition by month(Invoices.InvoiceDate)) as [Нарастающий итог по месяцу]
from Sales.Invoices
join Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
where Invoices.InvoiceDate >= '2015-01-01'
group by Invoices.InvoiceDate
order by 1;

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

select 
       InvoiceMonth,
       ItemsPopularity.StockItemID,
       StockItems.StockItemName
from (
    select
        month(Invoices.InvoiceDate) as InvoiceMonth,
        StockItemID,
        sum(InvoiceLines.Quantity) as TotalQuantity,
        row_number() over (partition by month(Invoices.InvoiceDate) order by sum(InvoiceLines.Quantity) desc) as rn
    from Sales.Invoices
    join Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
    where Invoices.InvoiceDate between '2016-01-01' and '2016-12-31'
    group by  
        month(Invoices.InvoiceDate),
        StockItemID
    ) as ItemsPopularity
join Warehouse.StockItems on ItemsPopularity.StockItemID = StockItems.StockItemID
where rn <=2
order by 1

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе 
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select 
    ROW_NUMBER() over (partition by left(StockItemName,1) order by StockItemID) as rn,
    left(StockItemName,1) as FirstSymbol, 
    StockItemID,
    StockItemName,
    Brand,
    count(StockItemID) over () as TotalCount,
    count(StockItemID) over (partition by left(StockItemName,1)) AS GroupCount,
    lead(StockItemID,1) over (order by StockItemName) as NextItem,
    lag(StockItemID,1) over (order by StockItemName) as PrevItem,
    lag(StockItemName,2,'No items') over (order by StockItemName) as PrevItem2,
    ntile(30) over (ORDER BY TypicalWeightPerUnit) as WeightPerUnitGroup
from Warehouse.StockItems
order by FirstSymbol,rn

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

select
    SalespersonPersonID,
    Salesman,
    CustomerID,
    Customer,
    InvoiceDate,
    InvoiceSum
from (
    select 
        Invoices.SalespersonPersonID, 
        sm.FullName as Salesman, 
        Invoices.CustomerID, 
        cust.FullName as Customer,
        Invoices.InvoiceDate, 
        sum(InvoiceLines.Quantity*InvoiceLines.UnitPrice) as InvoiceSum,
        ROW_NUMBER() over (partition by Invoices.SalespersonPersonID order by Invoices.InvoiceDate desc) as rn
    from Sales.Invoices
    join Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
    join Application.People as sm on SalespersonPersonID = sm.PersonID
    join Application.People as cust on CustomerID = cust.PersonID
    group by SalespersonPersonID, sm.FullName, CustomerID, cust.FullName, InvoiceDate
) as t
where rn = 1

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select 
    CustomerID,
    Customer,
    StockItemID,
    UnitPrice,
    InvoiceDate
from (
    select 
        Invoices.CustomerID,
        cust.FullName as Customer,
        InvoiceLines.StockItemID,
        InvoiceLines.UnitPrice,
        max(Invoices.InvoiceDate) as InvoiceDate,
        ROW_NUMBER() over (partition by Invoices.CustomerID order by InvoiceLines.UnitPrice desc) as rn
    from Sales.Invoices
    join Sales.InvoiceLines on Invoices.InvoiceID = InvoiceLines.InvoiceID
    join Application.People as cust on CustomerID = cust.PersonID
    group by Invoices.CustomerID,
        cust.FullName,
        InvoiceLines.StockItemID,
        InvoiceLines.UnitPrice
) as t
where rn<=2
order by CustomerID asc, UnitPrice desc