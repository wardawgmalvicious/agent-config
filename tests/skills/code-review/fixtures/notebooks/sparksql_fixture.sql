SELECT TOP 10 *
FROM [Order] o
INNER JOIN Customer c ON c.CustomerId = o.CustomerId
WHERE o.OrderDate >= DATEADD(day, -30, GETDATE())
ORDER BY o.OrderTotal DESC

SELECT
    CustomerId,
    SUM(OrderTotal) AS Total
FROM Order
WHERE LOWER(Region) = 'emea'
GROUP BY CustomerId