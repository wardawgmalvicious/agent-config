SELECT *
FROM Customer c, [Order] o
WHERE o.customer_id = c.customer_id
AND o.order_date >= DATEADD(month, -12, GETDATE())
ORDER BY o.order_total DESC

select c.customer_name,
       sum(o.order_total) total_spend,
       count(o.order_id) order_count
from dbo.Customer c
join dbo.[Order] o on o.CustomerId = c.CustomerId
where c.IsActive = 1
group by c.customer_name
having sum(o.order_total) > 1000