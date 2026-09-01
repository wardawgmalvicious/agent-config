CREATE VIEW [ingest].[vw_LatestRun]
AS
SELECT  c.[EntityName],
        MAX(c.[LoadedAt]) AS [LastLoadedAt]
FROM    [ingest].[Control] AS c
WHERE   c.[IsActive] = 1
GROUP BY c.[EntityName];
