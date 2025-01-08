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
    WHERE customer_id > 0),
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
		NTILE(3) OVER (ORDER BY recency) AS R_score,
		NTILE(3) OVER (ORDER BY frequency) AS F_score,
		NTILE(3) OVER (ORDER BY monetary) AS M_score
	FROM rfm_value),
rfm AS(
	SELECT
		*,
        CONCAT(R_score, F_score, M_score) AS RFM_score
	FROM rfm_score)

SELECT
    *,
    CASE
         WHEN RFM_score IN (222) THEN 'About to Sleep'
		 WHEN RFM_score IN (213, 221) THEN 'At Risk'
		 WHEN RFM_score IN (212, 211) THEN 'Cant Lose Them'
		 WHEN RFM_score IN (333) THEN 'Champions'
		 WHEN RFM_score IN (232, 223, 231) THEN 'Customers Needing Attention'
         WHEN RFM_score IN (132, 123, 131, 122, 113, 121, 112) THEN 'Hibernating'
         WHEN RFM_score IN (111) THEN 'Lost'
         WHEN RFM_score IN (332) THEN 'Loyal Customers'
         WHEN RFM_score IN (323) THEN 'Potential Loyalist'
         WHEN RFM_score IN (233, 133) THEN 'Promising'
         WHEN RFM_score IN (331, 322, 313, 321, 312, 311) THEN 'Recent Customers'
    END AS customer_segment
FROM rfm;
