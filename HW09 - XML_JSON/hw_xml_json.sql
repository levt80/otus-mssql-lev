/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/

/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

-- Вариант с OPENXML

DECLARE @xmlDocument XML;

SELECT @xmlDocument = BulkColumn
FROM OPENROWSET 
(BULK 'f:\Repository\otus-mssql-lev\HW09 - XML_JSON\StockItems.xml', SINGLE_CLOB)
as data;

SELECT @xmlDocument AS [@xmlDocument];
DECLARE @docHandle INT;
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument;

MERGE INTO Warehouse.StockItems as mtarget
USING (
    SELECT *
    FROM OPENXML(@docHandle, N'/StockItems/Item')
    WITH ( 
        [StockItemName] NVARCHAR(100) '@Name',
	    [SupplierID] INT 'SupplierID',
	    [UnitPackageID] INT 'Package/UnitPackageID',
	    [OuterPackageID] INT 'Package/OuterPackageID',
        [QuantityPerOuter] INT 'Package/QuantityPerOuter',
        [TypicalWeightPerUnit] DECIMAL(18,3) 'Package/TypicalWeightPerUnit',
        [LeadTimeDays] INT 'LeadTimeDays',
        [IsChillerStock] BIT 'IsChillerStock',
        [TaxRate] DECIMAL(18,3) 'TaxRate',
        [UnitPrice] DECIMAL(18,2) 'UnitPrice'
    )
) as msource
ON mtarget.StockItemName = msource.StockItemName
WHEN MATCHED THEN UPDATE
    SET mtarget.[SupplierID] = msource.[SupplierID],
        mtarget.[UnitPackageID] = msource.[UnitPackageID],
        mtarget.[OuterPackageID] = msource.[OuterPackageID],
        mtarget.[QuantityPerOuter] = msource.[QuantityPerOuter],
        mtarget.[TypicalWeightPerUnit] = msource.[TypicalWeightPerUnit],
        mtarget.[LeadTimeDays] = msource.[LeadTimeDays],
        mtarget.[IsChillerStock] = msource.[IsChillerStock],
        mtarget.[TaxRate] = msource.[TaxRate],
        mtarget.[UnitPrice] = msource.[UnitPrice],
        mtarget.[LastEditedBy] = 1
WHEN NOT MATCHED THEN INSERT
    ([StockItemName],[SupplierID],[UnitPackageID],[OuterPackageID],[QuantityPerOuter],[TypicalWeightPerUnit],[LeadTimeDays],[IsChillerStock],[TaxRate],[UnitPrice],[LastEditedBy])
    VALUES (
        msource.[StockItemName],
        msource.[SupplierID],
        msource.[UnitPackageID],
        msource.[OuterPackageID],
        msource.[QuantityPerOuter],
        msource.[TypicalWeightPerUnit],
        msource.[LeadTimeDays],
        msource.[IsChillerStock],
        msource.[TaxRate],
        msource.[UnitPrice],
        1
        );

EXEC sp_xml_removedocument @docHandle;


-- Вариант с XQuery

DECLARE @x XML;
SET @x = ( 
  SELECT * FROM OPENROWSET
  (BULK 'f:\Repository\otus-mssql-lev\HW09 - XML_JSON\StockItems.xml',
   SINGLE_CLOB) AS d);

MERGE INTO Warehouse.StockItems as mtarget
USING (
    SELECT
        t.StockItems.value('(@Name)','NVARCHAR(100)') as [StockItemName],
        t.StockItems.value('(SupplierID)[1]','INT') as SupplierID,
        t.StockItems.value('(Package/UnitPackageID)[1]','INT') as UnitPackageID,
        t.StockItems.value('(Package/OuterPackageID)[1]','INT') as OuterPackageID,
        t.StockItems.value('(Package/QuantityPerOuter)[1]','INT') as QuantityPerOuter,
        t.StockItems.value('(Package/TypicalWeightPerUnit)[1]','DECIMAL(18,3)') as TypicalWeightPerUnit,
        t.StockItems.value('(LeadTimeDays)[1]','INT') as LeadTimeDays,
        t.StockItems.value('(IsChillerStock)[1]','BIT') as IsChillerStock,
        t.StockItems.value('(TaxRate)[1]','DECIMAL(18,3)') as TaxRate,
        t.StockItems.value('(UnitPrice)[1]','DECIMAL(18,2)') as UnitPrice
    FROM @x.nodes('/StockItems/Item') as t(StockItems)
) as msource
ON mtarget.StockItemName = msource.StockItemName
WHEN MATCHED THEN UPDATE
    SET mtarget.[SupplierID] = msource.[SupplierID],
        mtarget.[UnitPackageID] = msource.[UnitPackageID],
        mtarget.[OuterPackageID] = msource.[OuterPackageID],
        mtarget.[QuantityPerOuter] = msource.[QuantityPerOuter],
        mtarget.[TypicalWeightPerUnit] = msource.[TypicalWeightPerUnit],
        mtarget.[LeadTimeDays] = msource.[LeadTimeDays],
        mtarget.[IsChillerStock] = msource.[IsChillerStock],
        mtarget.[TaxRate] = msource.[TaxRate],
        mtarget.[UnitPrice] = msource.[UnitPrice],
        mtarget.[LastEditedBy] = 1
WHEN NOT MATCHED THEN INSERT
    ([StockItemName],[SupplierID],[UnitPackageID],[OuterPackageID],[QuantityPerOuter],[TypicalWeightPerUnit],[LeadTimeDays],[IsChillerStock],[TaxRate],[UnitPrice],[LastEditedBy])
    VALUES (
        msource.[StockItemName],
        msource.[SupplierID],
        msource.[UnitPackageID],
        msource.[OuterPackageID],
        msource.[QuantityPerOuter],
        msource.[TypicalWeightPerUnit],
        msource.[LeadTimeDays],
        msource.[IsChillerStock],
        msource.[TaxRate],
        msource.[UnitPrice],
        1
        );


/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

/* Скрипт формирования структуры XML */
select 
    StockItemName AS [@Name], 
    SupplierID as [SupplierID], 
    UnitPackageID as [Package/UnitPackageID], 
    OuterPackageID as [Package/OuterPackageID], 
    QuantityPerOuter as [Package/QuantityPerOuter], 
    TypicalWeightPerUnit as [Package/TypicalWeightPerUnit], 
    LeadTimeDays as [LeadTimeDays], 
    IsChillerStock as [IsChillerStock], 
    TaxRate as [TaxRate], 
    UnitPrice as [UnitPrice]
from WideWorldImporters.Warehouse.StockItems 
FOR XML PATH('Item'), ROOT('StockItems'), TYPE;

/* Выгрузка */
DECLARE @out varchar(8000);
DECLARE @filename varchar(100) = 'F:\BCP\MyStockItems.xml'
SET @out = 'bcp "select StockItemName AS [@Name], SupplierID as [SupplierID], UnitPackageID as [Package/UnitPackageID], OuterPackageID as [Package/OuterPackageID], QuantityPerOuter as [Package/QuantityPerOuter], TypicalWeightPerUnit as [Package/TypicalWeightPerUnit], LeadTimeDays as [LeadTimeDays], IsChillerStock as [IsChillerStock], TaxRate as [TaxRate], UnitPrice as [UnitPrice] from WideWorldImporters.Warehouse.StockItems FOR XML PATH(''Item''), ROOT(''StockItems''), TYPE" queryout ' + @filename + ' -c -T -S ' + @@SERVERNAME;
EXEC master..xp_cmdshell @out;


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select 
    StockItemID,
    StockItemName,
    JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture,
    JSON_VALUE(CustomFields, '$.Tags[0]') as FirstTag
from Warehouse.StockItems


/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

select 
    StockItemID,
    StockItemName,
    JSON_QUERY(CustomFields, '$.Tags') as Tags
from Warehouse.StockItems
CROSS APPLY OPENJSON(CustomFields, '$.Tags') as cf_tags
where cf_tags.value = 'Vintage' 

