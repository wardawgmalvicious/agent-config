CREATE TABLE [ingest].[Control] (
    [ControlId]   INT           NOT NULL,
    [EntityName]  VARCHAR (128) NOT NULL,
    [IsActive]    BIT           NOT NULL,
    [LoadedAt]    DATETIME2 (6) NOT NULL
);
