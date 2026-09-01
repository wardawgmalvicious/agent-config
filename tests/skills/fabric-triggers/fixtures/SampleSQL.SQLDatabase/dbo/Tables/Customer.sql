-- Deliberately uses constructs Fabric Warehouse forbids but Fabric SQL Database allows.
CREATE TABLE [dbo].[Customer] (
    [CustomerId]  INT            IDENTITY (1, 1) NOT NULL,
    [Name]        NVARCHAR (200) NOT NULL,
    [Balance]     MONEY          NULL,
    [CreatedAt]   DATETIME       CONSTRAINT [DF_Customer_CreatedAt] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED ([CustomerId] ASC)
);
