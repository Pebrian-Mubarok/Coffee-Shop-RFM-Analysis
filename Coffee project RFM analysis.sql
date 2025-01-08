WITH new_transaction AS (
	SELECT
		CONCAT(sales_outlet_id,'-',customer_id) AS id_customer,
        sales_outlet_id,
		MAX(transaction_date) AS last_transaction,
		COUNT(distinct transaction_id) AS frequency,
		ROUND(SUM(quantity*unit_price),0) AS monetary
	FROM coffee.transaction_data
	WHERE customer_id > 0
	GROUP BY 1),
last_transaction AS (
	SELECT
    MAX(transaction_date) AS overall_last_transaction
    FROM coffee.transaction_data
    where customer_id > 0),
rfm_value AS(
	SELECT
		n.id_customer,
        sales_outlet_id,
		ABS(DATEDIFF(n.last_transaction, l.overall_last_transaction)) AS recency,
		n.frequency,
		n.monetary
	FROM new_transaction n
	JOIN last_transaction l
	GROUP BY 1
	ORDER BY 2),
rfm_score AS(
	SELECT
		*,
		ntile(3) over (order by recency) AS R_score,
		ntile(3) over (order by frequency) AS F_score,
		ntile(3) over (order by monetary) AS M_score
	FROM rfm_value),
rfm AS(
	SELECT
		*,
        CONCAT(R_score, F_score, M_score) AS RFM_score
	FROM rfm_score)

SELECT
    *,
    CASE
         when RFM_score in (222) then 'About to Sleep'
		 when RFM_score in (213, 221) then 'At Risk'
		 when RFM_score in (212, 211) then 'Cant Lose Them'
		 when RFM_score in (333) then 'Champions'
		 when RFM_score in (232, 223, 231) then 'Customers Needing Attention'
         when RFM_score in (132, 123, 131, 122, 113, 121, 112) then 'Hibernating'
         when RFM_score in (111) then 'Lost'
         when RFM_score in (332) then 'Loyal Customers'
         when RFM_score in (323) then 'Potential Loyalist'
         when RFM_score in (233, 133) then 'Promising'
         when RFM_score in (331, 322, 313, 321, 312, 311) then 'Recent Customers'
    END AS customer_segment
FROM rfm;