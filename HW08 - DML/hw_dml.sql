/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

insert into [Purchasing].[Suppliers]
    (SupplierID
    ,SupplierName
    ,SupplierCategoryID	
    ,PrimaryContactPersonID	
    ,AlternateContactPersonID	
    ,DeliveryCityID	
    ,PostalCityID	
    ,PaymentDays	
    ,PhoneNumber	
    ,FaxNumber	
    ,WebsiteURL	
    ,DeliveryAddressLine1	
    ,DeliveryPostalCode	
    ,PostalAddressLine1	
    ,PostalPostalCode	
    ,LastEditedBy)
values
    (NEXT VALUE FOR [Sequences].[SupplierID],N'NewSupplier1',2,43,40,17346,17346,30,N'(218) 555-0105',N'(218) 555-0105',N'http://www.thephone-company.com',N'Level 83',56732,N'PO Box 3837',56732,1),
    (NEXT VALUE FOR [Sequences].[SupplierID],N'NewSupplier2',2,43,40,17346,17346,30,N'(218) 555-0105',N'(218) 555-0105',N'http://www.thephone-company.com',N'Level 83',56732,N'PO Box 3837',56732,1),
    (NEXT VALUE FOR [Sequences].[SupplierID],N'NewSupplier3',2,43,40,17346,17346,30,N'(218) 555-0105',N'(218) 555-0105',N'http://www.thephone-company.com',N'Level 83',56732,N'PO Box 3837',56732,1),
    (NEXT VALUE FOR [Sequences].[SupplierID],N'NewSupplier4',2,43,40,17346,17346,30,N'(218) 555-0105',N'(218) 555-0105',N'http://www.thephone-company.com',N'Level 83',56732,N'PO Box 3837',56732,1),
    (NEXT VALUE FOR [Sequences].[SupplierID],N'NewSupplier5',2,43,40,17346,17346,30,N'(218) 555-0105',N'(218) 555-0105',N'http://www.thephone-company.com',N'Level 83',56732,N'PO Box 3837',56732,1)

SELECT *
FROM [Purchasing].[Suppliers]

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM [Purchasing].[Suppliers]
WHERE SupplierID = 14


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE [Purchasing].[Suppliers]
Set SupplierName = N'NewUpdatedSupplier'
where SupplierName = N'NewSupplier2'

/*
4. Написать MERGE, который вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
declare @source table
    (SupplierID int
    ,SupplierName nvarchar(100)
    )

insert into @source
    (SupplierID
    ,SupplierName)
values
    (19,N'NewSupplier6'),
    (16,N'NewSupplier7')

MERGE [Purchasing].[Suppliers] AS Target
USING @source AS Source
    ON (Target.SupplierID = Source.SupplierID)
WHEN MATCHED 
    THEN UPDATE 
        SET SupplierName = Source.SupplierName
WHEN NOT MATCHED 
    THEN INSERT (SupplierID,SupplierName,SupplierCategoryID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryCityID,PostalCityID,PaymentDays,PhoneNumber,FaxNumber,WebsiteURL,DeliveryAddressLine1,DeliveryPostalCode,PostalAddressLine1,PostalPostalCode,LastEditedBy)
         VALUES (Source.SupplierID, Source.SupplierName,2,43,40,17346,17346,30,N'(218) 555-0105',N'(218) 555-0105',N'http://www.thephone-company.com',N'Level 83',56732,N'PO Box 3837',56732,1)
;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bcp in
*/

DECLARE @out varchar(250);
set @out = 'bcp WideWorldImporters.Purchasing.Suppliers  OUT "F:\BCP\Suppliers.txt" -T -S ' + @@SERVERNAME + ' -c';
EXEC master..xp_cmdshell @out


DROP TABLE IF EXISTS WideWorldImporters.Purchasing.Suppliers_Copy;
SELECT * INTO WideWorldImporters.Purchasing.Suppliers_Copy FROM WideWorldImporters.Purchasing.Suppliers
WHERE 1 = 2; 

DECLARE @in varchar(250);
set @in = 'bcp WideWorldImporters.Purchasing.Suppliers_Copy IN "F:\BCP\Suppliers.txt" -T -S ' + @@SERVERNAME + ' -c';
EXEC master..xp_cmdshell @in;

