
USE Sarbajit;

-- The distribution of account balances across different regions

SELECT
    g.GeographyLocation AS Region,
    COUNT(*) AS Total_customers,
    AVG(bc.Balance) AS Average_balance,
    MAX(bc.Balance) AS Maximum_balance,
    MIN(bc.Balance) AS Minimum_balance,
    STDEV(bc.Balance) AS Balance_stan_dev
FROM Bank_Churn bc
JOIN Customer_Info ci ON bc.CustomerId = ci.CustomerId
JOIN Geography g ON ci.GeographyID = g.GeographyID
GROUP BY g.GeographyLocation;


-- Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year

SELECT TOP 5
    CustomerId,
    EstimatedSalary
FROM Customer_Info
WHERE [Bank_DOJ] >= '2019-10-01'
  AND [Bank_DOJ] <  '2020-01-01'
ORDER BY EstimatedSalary DESC;

-- The average number of products used by customers who have a credit card.

SELECT
    AVG (NumOfProducts) AS Average_Num_of_Products_With_Credit_Card
FROM Bank_Churn
WHERE HasCrCard = 1;

-- The churn rate by gender for the most recent year in the dataset.

WITH Churn_count AS (
    SELECT
        ci.GenderID,
        SUM(CASE WHEN bc.Exited = 1 THEN 1 ELSE 0 END) AS Churned_Customer,
        COUNT(*) AS Total_customers
    FROM Customer_Info ci
    JOIN Bank_Churn bc 
        ON ci.CustomerId = bc.CustomerId
    WHERE YEAR(ci.Bank_DOJ) = (
        SELECT MAX(YEAR(Bank_DOJ)) 
        FROM Customer_Info
    )
    GROUP BY ci.GenderID
)
SELECT
    g.genderCategory AS Gender,
    c.Churned_Customer,
    c.Total_customers,
    ROUND(
        c.Churned_Customer * 100.0 / c.Total_customers,
        2
    ) AS Churn_rate_percentage
FROM Churn_count c
JOIN Gender g 
    ON c.GenderID = g.GenderID;


-- Compare the average credit score of customers who have exited and those who remain.

SELECT
    CASE 
        WHEN Exited = 1 THEN 'EXITED'
        ELSE 'REMAIN'
    END AS Customer_Status,
    AVG(CreditScore) AS Average_credit_score
FROM Bank_Churn
GROUP BY
    CASE 
        WHEN Exited = 1 THEN 'EXITED'
        ELSE 'REMAIN'
    END;


-- Which gender has a higher average estimated salary, and how does it relate to the number of active accounts

SELECT
    g.GenderCategory AS Gender,
    AVG(ci.EstimatedSalary) AS Avg_Estimated_Salary,
    SUM(CAST(bc.IsActiveMember AS INT)) AS Num_Active_Accounts
FROM Customer_Info ci
JOIN Gender g 
    ON ci.GenderID = g.GenderID
JOIN Bank_Churn bc 
    ON ci.CustomerId = bc.CustomerId
GROUP BY g.GenderCategory
ORDER BY Avg_Estimated_Salary DESC;

-- Segment the customers based on their credit score and identify the segment with the highest exit rate.

WITH CreditScoreSegments AS(
    SELECT
        CASE
            WHEN CreditScore BETWEEN 800 AND 850 THEN 'Very Poor'
			WHEN CreditScore BETWEEN 740 AND 799 THEN 'Poor'
			WHEN CreditScore BETWEEN 670 AND 739 THEN 'Fair'
			WHEN CreditScore BETWEEN 580 AND 669 THEN 'Great'
			WHEN CreditScore BETWEEN 300 AND 579 THEN 'Excellent'
		END AS CreditScoreSegment,
		Exited
	FROM bank_churn
)

SELECT TOP 1
    CreditScoreSegment,
    COUNT(*) AS TotalCustomers,
    SUM(CAST(Exited AS INT)) AS ExitedCustomers,
    SUM(CAST(Exited AS INT)) * 1.0 / COUNT(*) AS ExitRate
FROM CreditScoreSegments
GROUP BY CreditScoreSegment
ORDER BY ExitRate DESC;

-- Find out which geographic region has the highest number of active customers with a tenure greater than 5 years

SELECT TOP 1
    g.GeographyLocation,
	COUNT(*) AS active_customers
FROM bank_churn bc
JOIN Customer_Info ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1 AND bc.Tenure > 5
GROUP BY GeographyLocation
ORDER BY active_customers DESC;

-- impact of having a credit card on customer churn based on the available data

SELECT
    HasCrCard,
    SUM(CAST(Exited AS INT)) * 100.0 / COUNT(CustomerId) AS churn_rate
FROM bank_churn
GROUP BY HasCrCard;

-- For customers who have exited and the most common number of products they have used

SELECT TOP 1
    	NumOfProducts AS most_common_num_of_products_used,
    COUNT(*) AS num_of_customers
FROM bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY num_of_customers DESC;

-- Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly)

WITH JoinDates AS (
    SELECT
        YEAR(Bank_DOJ) AS join_year,
        MONTH(Bank_DOJ) AS join_month
    FROM Customer_Info
)
SELECT
    join_year,
    join_month,
    COUNT(*) AS num_of_customers
FROM JoinDates
GROUP BY join_year, join_month
ORDER BY join_year, join_month;

-- Analyze the relationship between the number of products and the account balance for customers who have exited

SELECT
	NumOfProducts,
    AVG(Balance) AS average_balance
FROM bank_churn
WHERE Exited = 1
GROUP BY NumOfProducts;

-- Identify any potential outliers in terms of balance among customers who have remained with the bank

SELECT 
	CustomerId, 
    Balance
FROM bank_churn
WHERE
	IsActiveMember = 1 AND Exited = 1
ORDER BY Balance DESC;

-- Genderwise average income of males and females in each geography id and ranking of the gender according to the average value

SELECT
	RANK() OVER(PARTITION BY geo.GeographyLocation ORDER BY AVG(EstimatedSalary) DESC) AS avg_income_rank,
    gen.GenderCategory,
	geo.GeographyLocation,
    AVG(EstimatedSalary) AS avg_income
FROM Customer_Info ci
JOIN gender gen ON ci.GenderID = gen.GenderID
JOIN geography geo ON ci.GeographyID = geo.GeographyID
GROUP BY
	gen.GenderCategory, 
    geo.GeographyLocation;

-- The average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+)

WITH AgeBuckets AS (
    SELECT
        CASE
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 31 AND 50 THEN '31-50'
            ELSE '50+'
        END AS AgeBracket,
        Tenure
    FROM Customer_Info ci
    JOIN bank_churn bc 
        ON ci.CustomerId = bc.CustomerId
    WHERE Exited = 1
)
SELECT
    AgeBracket,
    AVG(Tenure) AS avg_tenure
FROM AgeBuckets
GROUP BY AgeBracket
ORDER BY AgeBracket;

-- Correlation between salary and balance for all customers

SELECT 
    (COUNT(*) * SUM(bc.Balance * ci.EstimatedSalary) - SUM(bc.Balance) * SUM(ci.EstimatedSalary)) /
    (SQRT((COUNT(*) * SUM(bc.Balance * bc.Balance) - SUM(bc.Balance) * SUM(bc.Balance)) *
          (COUNT(*) * SUM(ci.EstimatedSalary * ci.EstimatedSalary) - SUM(ci.EstimatedSalary) * SUM(ci.EstimatedSalary))))
    AS correlation_all
FROM bank_churn bc
JOIN Customer_Info ci ON bc.CustomerId = ci.CustomerId;

-- Correlation between salary and balance for customers who have not exited

SELECT 
    (COUNT(*) * SUM(bc.Balance * ci.EstimatedSalary) - SUM(bc.Balance) * SUM(ci.EstimatedSalary)) /
    (SQRT((COUNT(*) * SUM(bc.Balance * bc.Balance) - SUM(bc.Balance) * SUM(bc.Balance)) *
          (COUNT(*) * SUM(ci.EstimatedSalary * ci.EstimatedSalary) - SUM(ci.EstimatedSalary) * SUM(ci.EstimatedSalary))))
    AS correlation_not_exited
FROM bank_churn bc
JOIN Customer_Info ci ON bc.CustomerId = ci.CustomerId
WHERE bc.Exited = 0;

-- Correlation between salary and balance for customers who have exited

SELECT 
    (COUNT(*) * SUM(bc.Balance * ci.EstimatedSalary) - SUM(bc.Balance) * SUM(ci.EstimatedSalary)) /
    (SQRT((COUNT(*) * SUM(bc.Balance * bc.Balance) - SUM(bc.Balance) * SUM(bc.Balance)) *
          (COUNT(*) * SUM(ci.EstimatedSalary * ci.EstimatedSalary) - SUM(ci.EstimatedSalary) * SUM(ci.EstimatedSalary))))
    AS correlation_exited
FROM bank_churn bc
JOIN Customer_Info ci ON bc.CustomerId = ci.CustomerId
WHERE bc.Exited = 1;

-- correlation between the salary and the Credit score of customers
SELECT
(
    COUNT(*) * SUM(CAST(bc.CreditScore AS FLOAT) * CAST(ci.EstimatedSalary AS FLOAT))
    - SUM(CAST(bc.CreditScore AS FLOAT)) * SUM(CAST(ci.EstimatedSalary AS FLOAT))
)
/
SQRT(
    (
        COUNT(*) * SUM(CAST(bc.CreditScore AS FLOAT) * CAST(bc.CreditScore AS FLOAT))
        - POWER(SUM(CAST(bc.CreditScore AS FLOAT)), 2)
    )
    *
    (
        COUNT(*) * SUM(CAST(ci.EstimatedSalary AS FLOAT) * CAST(ci.EstimatedSalary AS FLOAT))
        - POWER(SUM(CAST(ci.EstimatedSalary AS FLOAT)), 2)
    )
) AS correlation_CreditScore_salary
FROM bank_churn bc
JOIN Customer_Info ci
ON bc.CustomerId = ci.CustomerId;


-- Rank each bucket of credit score as per the number of customers who have churned the bank

WITH t AS (
    SELECT
        CASE
            WHEN CreditScore BETWEEN 800 AND 850 THEN '800-850'
            WHEN CreditScore BETWEEN 740 AND 799 THEN '740-799'
            WHEN CreditScore BETWEEN 670 AND 739 THEN '670-739'
            WHEN CreditScore BETWEEN 580 AND 669 THEN '580-669'
            ELSE '300-579'
        END AS Credit_Score_Bucket
    FROM bank_churn bc
    JOIN Customer_Info ci
        ON bc.CustomerId = ci.CustomerId
    WHERE Exited = 1
)

SELECT
    RANK() OVER (ORDER BY COUNT(*) DESC) AS crd_scr_rank,
    Credit_Score_Bucket,
    COUNT(*) AS num_of_churned_customers
FROM t
GROUP BY Credit_Score_Bucket
ORDER BY num_of_churned_customers DESC;


-- According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets that have lesser than average number of credit cards per bucket

WITH AgeBuckets AS (
    SELECT
        CASE
            WHEN ci.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN ci.Age BETWEEN 31 AND 50 THEN '31-50'
            ELSE '50+'
        END AS AgeBucket,
        COUNT(*) AS num_of_customers,
        SUM(CASE WHEN bc.HasCrCard = 1 THEN 1 ELSE 0 END) AS customers_with_crcd
    FROM Customer_Info ci
    JOIN bank_churn bc
        ON ci.CustomerId = bc.CustomerId
    GROUP BY
        CASE
            WHEN ci.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN ci.Age BETWEEN 31 AND 50 THEN '31-50'
            ELSE '50+'
        END
),

AvgCreditCards AS (
    SELECT AVG(customers_with_crcd * 1.0) AS avg_crcds
    FROM AgeBuckets
)

SELECT
    ab.AgeBucket,
    ab.num_of_customers,
    ab.customers_with_crcd
FROM AgeBuckets ab
CROSS JOIN AvgCreditCards ac
WHERE ab.customers_with_crcd < ac.avg_crcds
ORDER BY ab.customers_with_crcd DESC;

-- Rank the Locations as per the number of people who have churned the bank and average balance of the customers.

SELECT
    RANK() OVER (
        ORDER BY SUM(CAST(bc.Exited AS INT)) DESC,
                 AVG(bc.Balance) DESC
    ) AS location_rank,

    g.GeographyLocation,

    SUM(CAST(bc.Exited AS INT)) AS num_of_customers,

    ROUND(AVG(bc.Balance), 2) AS avg_balance

FROM Customer_Info ci
JOIN bank_churn bc
    ON ci.CustomerId = bc.CustomerId
JOIN geography g
    ON ci.GeographyID = g.GeographyID

GROUP BY g.GeographyLocation;

-- As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.

IF COL_LENGTH('Customer_Info', 'CustomerID_Surname') IS NULL
BEGIN
    ALTER TABLE Customer_Info
    ADD CustomerID_Surname VARCHAR(255);
END
GO

UPDATE Customer_Info
SET CustomerID_Surname =
    CAST(CustomerId AS VARCHAR(50)) + '-' + ISNULL(Surname, '');
GO

SELECT
    CustomerId,
    Surname,
    CustomerID_Surname
FROM Customer_Info;
GO

-- Behaviour Analysis

-- Patterns obsreved in the spending habits of long-term customers compared to new customers and findings about the customer loyalty

SELECT
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END AS TenureCategory,

    ROUND(AVG(CAST(Exited AS FLOAT)) * 100, 2) AS churn_rate

FROM Bank_Churn

GROUP BY
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END

ORDER BY churn_rate DESC;

-- Exit Count by Tenure Category
SELECT
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END AS TenureCategory,

    Exited,

    COUNT(*) AS num_of_customers

FROM Bank_Churn

GROUP BY
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END,
    Exited

ORDER BY
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END;

-- Credit Card Usage by Tenure Category

SELECT
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END AS TenureCategory,

    HasCrCard,

    COUNT(*) AS num_of_customers

FROM Bank_Churn

GROUP BY
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END,
    HasCrCard

ORDER BY
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END,
    HasCrCard;

-- Product Ownership by Tenure Category

SELECT
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END AS TenureCategory,
    NumOfProducts,
    COUNT(*) AS num_of_customers
FROM Bank_Churn
GROUP BY
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END,
    NumOfProducts
ORDER BY TenureCategory DESC;

-- Average Balance by Tenure Category

SELECT
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END AS TenureCategory,
    ROUND(AVG(Balance), 2) AS avg_balance
FROM Bank_Churn
GROUP BY
    CASE
        WHEN Tenure <= 5 THEN 'New Customer'
        ELSE 'Long Term Customer'
    END
ORDER BY avg_balance DESC;


-- Product Affinity Study:

-- Finding Which bank products or services are most commonly used together, and how might this influence cross-selling strategies

SELECT
    NumOfProducts,
    COUNT(*) AS num_customers
FROM Bank_Churn
WHERE
	IsActiveMember = 1 AND HasCrCard = 1
GROUP BY
    NumOfProducts;


-- Geographic Market Trends:

-- Finding How do economic indicators in different geographic regions correlate with the number of active accounts and customer churn rates

-- Average Balance by GeographyLocation and Exit Category for Active Customers

SELECT
	g.GeographyLocation,
    bc.Exited,
    AVG(bc.Balance) AS avg_balance
FROM bank_churn bc
JOIN Customer_Info ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1
GROUP BY
	g.GeographyLocation,
    bc.Exited
ORDER BY 
	bc.Exited,
    g.GeographyLocation;


-- Active Exited Customers by Geography Location and Credit Score Category

SELECT
    g.GeographyLocation,
    CASE
        WHEN bc.CreditScore BETWEEN 800 AND 850 THEN '800 - 850'
        WHEN bc.CreditScore BETWEEN 740 AND 799 THEN '740 - 799'
        WHEN bc.CreditScore BETWEEN 670 AND 739 THEN '670 - 739'
        WHEN bc.CreditScore BETWEEN 580 AND 669 THEN '580 - 669'
        WHEN bc.CreditScore BETWEEN 300 AND 579 THEN '300 - 579'
    END AS CreditScoreCategory,
    SUM(CAST(bc.Exited AS INT)) AS Churned_customers
FROM Bank_Churn bc
JOIN Customer_Info ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1
GROUP BY
    g.GeographyLocation,
    CASE
        WHEN bc.CreditScore BETWEEN 800 AND 850 THEN '800 - 850'
        WHEN bc.CreditScore BETWEEN 740 AND 799 THEN '740 - 799'
        WHEN bc.CreditScore BETWEEN 670 AND 739 THEN '670 - 739'
        WHEN bc.CreditScore BETWEEN 580 AND 669 THEN '580 - 669'
        WHEN bc.CreditScore BETWEEN 300 AND 579 THEN '300 - 579'
    END
ORDER BY
    g.GeographyLocation DESC,
    CreditScoreCategory;


-- Active Exited Customers having Credit Cards by Geography Location

SELECT
    g.GeographyLocation,
    SUM(CAST(HasCrCard AS INT)) AS Credit_card_users,
    SUM(CAST(Exited AS INT)) AS Churned_customers
FROM Bank_Churn bc
JOIN Customer_Info ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1
GROUP BY g.GeographyLocation
ORDER BY g.GeographyLocation DESC;


-- Active Exited Customers by GeographyLocation and Number of Customers

SELECT
    g.GeographyLocation,
    bc.NumOfProducts,
    COUNT(*) AS Number_of_customers,
    SUM(CAST(bc.Exited AS INT)) AS Churned_customers
FROM Bank_Churn bc
JOIN Customer_Info ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1
GROUP BY
    g.GeographyLocation,
    bc.NumOfProducts
ORDER BY g.GeographyLocation DESC;

-- Average Estimated Salary by GeographyLocation and Exit Category for Active Customers

SELECT
	g.GeographyLocation,
    bc.Exited,
    AVG(ci.EstimatedSalary) AS avg_estimated_salary
FROM bank_churn bc
JOIN Customer_Info ci ON bc.CustomerId = ci.CustomerId
JOIN geography g ON ci.GeographyID = g.GeographyID
WHERE bc.IsActiveMember = 1
GROUP BY
	g.GeographyLocation,
    bc.Exited
ORDER BY 
	bc.Exited,
    g.GeographyLocation;


-- Risk Management Assessment:

-- Based on customer profiles, which demographic segments appear to pose the highest financial risk to the bank

-- Customers by Credit Score Category and Age Segment

WITH categorized AS (
    SELECT
        CASE
            WHEN bc.CreditScore BETWEEN 800 AND 850 THEN '800 - 850'
            WHEN bc.CreditScore BETWEEN 740 AND 799 THEN '740 - 799'
            WHEN bc.CreditScore BETWEEN 670 AND 739 THEN '670 - 739'
            WHEN bc.CreditScore BETWEEN 580 AND 669 THEN '580 - 669'
            ELSE '300 - 579'
        END AS CreditScoreCategory,

        CASE
            WHEN ci.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN ci.Age BETWEEN 31 AND 50 THEN '31-50'
            ELSE '50+'
        END AS AgeSegment

    FROM Bank_Churn bc
    JOIN Customer_Info ci
        ON bc.CustomerId = ci.CustomerId
)

SELECT
    AgeSegment,
    CreditScoreCategory,
    COUNT(*) AS number_of_customers
FROM categorized
GROUP BY
    AgeSegment,
    CreditScoreCategory
ORDER BY
    AgeSegment,
    CreditScoreCategory;

-- Customers by Tenure Category and Age Segment

WITH categorized AS (
    SELECT
        CASE
            WHEN bc.Tenure <= 5 THEN 'New Customer'
            ELSE 'Long Term Customer'
        END AS TenureCategory,

        CASE
            WHEN ci.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN ci.Age BETWEEN 31 AND 50 THEN '31-50'
            ELSE '50+'
        END AS AgeSegment
    FROM Bank_Churn bc
    JOIN Customer_Info ci
        ON bc.CustomerId = ci.CustomerId
)

SELECT
    AgeSegment,
    TenureCategory,
    COUNT(*) AS number_of_customers
FROM categorized
GROUP BY
    AgeSegment,
    TenureCategory
ORDER BY
    AgeSegment,
    TenureCategory;

-- Average of Balance and Customers with Balance less than Average Balance

SELECT
	(SELECT ROUND(AVG(Balance), 2) AS average_balance FROM Bank_Churn) AS average_balance,
	COUNT(*) AS customers_with_balance_less_than_average_balance
FROM Bank_Churn
WHERE Balance < (SELECT ROUND(AVG(Balance), 2) AS average_balance FROM Bank_Churn);

-- Average of Estimated Salary and Customers with Estimated Salary less than Average Estimated Salary

SELECT
	(SELECT ROUND(AVG(EstimatedSalary), 2) AS average_estimated_salary FROM Customer_Info) AS average_estimated_salary,
	COUNT(*) AS customers_with_estimated_salary_less_than_average_estimated_salary
FROM Customer_Info
WHERE EstimatedSalary < (SELECT ROUND(AVG(EstimatedSalary), 2) AS average_estimated_salary FROM Customer_Info);


-- Segmentation of customers based on demographics and account details

-- Segmentation by Gender and Geography

SELECT 
    c.CustomerId,
    c.Age,
    CASE 
        WHEN c.GenderID = 1 THEN 'Male'
        WHEN c.GenderID = 2 THEN 'Female'
        ELSE 'Other'
    END AS Gender,
    CASE 
        WHEN c.GeographyID = 1 THEN 'France'
        WHEN c.GeographyID = 2 THEN 'Spain'
        WHEN c.GeographyID = 3 THEN 'Germany'
        ELSE 'Unknown'
    END AS Geography,
    c.EstimatedSalary,
    c.Bank_DOJ,
    bc.CreditScore,
    bc.Tenure,
    bc.Balance,
    bc.NumOfProducts,
    bc.HasCrCard,
    bc.IsActiveMember,
    bc.Exited
FROM Customer_Info c
JOIN Bank_Churn bc ON c.CustomerId = bc.CustomerId;

-- Segmentation by Credit Score
SELECT 
    *,
    CASE 
        WHEN CreditScore >= 800 THEN 'Excellent'
        WHEN CreditScore >= 740 AND CreditScore < 800 THEN 'Very Good'
        WHEN CreditScore >= 670 AND CreditScore < 740 THEN 'Good'
        WHEN CreditScore >= 580 AND CreditScore < 670 THEN 'Fair'
        WHEN CreditScore >= 300 AND CreditScore < 580 THEN 'Poor'
        ELSE 'Unknown'
    END AS CreditScoreCategory
FROM Bank_Churn;

-- Segmentation by Age Group

SELECT 
    *,
    CASE 
        WHEN Age < 18 THEN 'Under 18'
        WHEN Age BETWEEN 18 AND 24 THEN '18-24'
        WHEN Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN Age BETWEEN 45 AND 54 THEN '45-54'
        WHEN Age BETWEEN 55 AND 64 THEN '55-64'
        WHEN Age >= 65 THEN '65+'
        ELSE 'Unknown'
    END AS AgeGroup
FROM Customer_Info

-- Segmentation by Tenure Group

SELECT 
    *,
    CASE 
        WHEN Tenure < 1 THEN '0-1 year'
        WHEN Tenure BETWEEN 1 AND 3 THEN '1-3 years'
        WHEN Tenure BETWEEN 4 AND 6 THEN '4-6 years'
        WHEN Tenure BETWEEN 7 AND 9 THEN '7-9 years'
        ELSE 'Unknown'
    END AS TenureGroup
FROM Bank_Churn;

-- The current churn rate per year and overall as well in the bank?

WITH CustomerData AS (
    SELECT
        bc.CustomerId,
        bc.Tenure,
        bc.Exited,
        YEAR(ci.Bank_DOJ) AS JoinYear
    FROM Bank_Churn bc
    JOIN Customer_Info ci
        ON bc.CustomerId = ci.CustomerId
)

SELECT
    AVG(CAST(Exited AS FLOAT)) AS OverallChurnRate,
    AVG(CAST(Exited AS FLOAT)) / 
        (MAX(JoinYear) - MIN(JoinYear) + 1.0) AS ChurnRatePerYear
FROM CustomerData;
