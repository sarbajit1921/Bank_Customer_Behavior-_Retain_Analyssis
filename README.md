# Bank Customer Churn Analysis

## Project Overview

Customer churn is one of the most expensive problems a bank quietly ignores until it becomes a crisis. Acquiring a new customer costs five to seven times more than keeping an existing one, yet most banks still treat churn as a reactive problem — they notice it after the account is closed.

This project flips that. Using a dataset covering customer demographics, account activity, product usage, and geography, the goal was to identify **who is likely to leave, when, and why** — before it happens.

**Tools used:** Microsoft SQL Server · Power BI

---

## Database Schema

The analysis runs across four relational tables:

| Table | Key Columns |

| `Bank_Churn` | CustomerId, CreditScore, Balance, NumOfProducts, HasCrCard, IsActiveMember, Tenure, Exited |
| `Customer_Info` | CustomerId, Surname, Age, GenderID, GeographyID, EstimatedSalary, Bank_DOJ |
| `Geography` | GeographyID, GeographyLocation |
| `Gender` | GenderID, GenderCategory |


## SQL Findings

Here's a breakdown of the analytical angles covered:

**Regional Balance Distribution**
Calculates average, max, min, and standard deviation of account balances per region — useful for spotting which markets hold higher-value but potentially at-risk customers.

**Top Earners by Join Quarter**
Identifies the top 5 customers by estimated salary who joined in Q4 — useful for understanding whether high-income customers joined during specific campaigns and whether they stayed.

**Credit Card Holders — Product Behaviour**
Finds the average number of products used by customers who hold a credit card. Credit card holders tend to be more deeply embedded, but are they actually using more services?

**Churn Rate by Gender (Latest Year)**
Calculates the exact churn percentage broken down by gender for the most recent year in the dataset using a CTE — cleaner and more reproducible than a nested subquery.

**Credit Score: Exited vs. Retained**
Directly compares the average credit score of customers who left versus those who stayed. The gap here tells you whether creditworthiness is a churn predictor or a red herring.

**Gender, Salary, and Active Accounts**
Looks at whether one gender earns more on average, and how that maps to the number of active accounts — because a high salary means nothing to retention if the customer isn't engaged.

**Credit Score Segmentation + Exit Rate**
Buckets customers into credit score bands and finds which segment has the highest exit rate. Spoiler: it's not always the low scorers.

**Geographic Loyalty — Long-Tenure Active Customers**
Finds the region with the most active customers who've stayed more than 5 years. This is your most stable market — worth protecting.

**Credit Card Impact on Churn**
Compares churn rates between customers who have a credit card and those who don't. Helps determine whether the card is a retention tool or just a product.

**Exited Customers — Product Usage Pattern**
Finds the most common number of products used by customers who churned. If the answer is "1", the bank has a cross-selling problem.

**Customer Join Trends — Seasonality Check**
Groups customers by year and month of joining to spot seasonal acquisition spikes — important for planning retention budgets around cohorts that arrived during specific periods.

**Products vs. Balance for Churned Customers**
Analyses whether churned customers who held more products also had higher balances — a pattern that would suggest product complexity (not product count) may be driving exits.

**Balance Outliers Among Active Members Who Exited**
Finds customers who were active *and* exited — and ranks them by balance. These are the most painful losses: engaged customers with money who still walked away.

**Gender-Wise Income by Geography (with Ranking)**
Uses `RANK() OVER (PARTITION BY ...)` to rank male vs. female average income within each region. Useful for understanding whether product offers should be region-and-gender-specific.

**Age Bracket Exit Tenure**
Groups exited customers into age brackets (18–30, 31–50, 50+) and finds the average tenure before they left. Younger customers leaving faster than older ones is a different problem than the reverse.

**Salary–Balance Correlation**
Calculates Pearson correlation coefficients — for all customers, for those who stayed, and for those who exited — to test whether high earners hold higher balances, and whether that changes for churners.

**Salary–Credit Score Correlation**
Tests whether income and credit score move together. If they don't, targeting by salary alone won't predict creditworthiness.

**Credit Score Buckets Ranked by Churn Volume**
Ranks credit score ranges by the absolute number of churned customers in each. This is different from exit *rate* — a medium-risk band can cause the most damage simply because it has the most customers.

**Age Buckets Below Average for Credit Card Ownership**
Finds age groups that have fewer credit card holders than the dataset average — identifying underserved segments where cross-selling could reduce churn risk.

**Geography Ranked by Churn + Balance**
Ranks regions simultaneously by number of churned customers and average account balance. A region that churns fewer customers but loses higher-balance accounts is a bigger revenue problem than it looks.

**CustomerID\_Surname Composite Column**
A practical schema modification — adds a `CustomerID_Surname` column formatted as `CustomerID-Surname` to support joining with external tables that use a composite primary key.

---

## Power BI Dashboard

## 💡 Key Insights

After running through every query, a few patterns stand out clearly:

**1. Geography matters more than people think.**
Churn is not uniform across regions. Certain locations show higher churn *and* higher average balances among the customers who left — meaning the revenue impact is disproportionately concentrated in specific markets.

**2. Single-product customers are the most vulnerable.**
The most common number of products used by exited customers was 1. Customers holding only one product have almost no switching cost. Every customer who never cross-sold is a churn risk waiting to happen.

**3. Active members still churn — and they're the most expensive losses.**
A non-trivial number of churned customers were flagged as active members. These aren't disengaged customers who drifted away — they made a deliberate choice to leave. That's a different problem entirely, and it points to service quality or competitor offers rather than engagement gaps.

**4. Middle-aged customers (31–50) represent the core risk segment.**
This group is large enough that even a moderate exit rate creates significant volume. Combined with the tenure data, this segment tends to leave earlier than the 50+ group — likely because they have more options and are more financially mobile.

**5. Credit score is not a strong churn predictor on its own.**
The difference in average credit score between exited and retained customers is smaller than expected. The segment with the highest *exit rate* is not always the lowest credit band — which means credit-based targeting for retention would miss a large portion of actual churners.

**6. Salary and balance are weakly correlated — especially for churned customers.**
High earners do not necessarily hold proportionally high balances. For churned customers, this gap widens — suggesting that high-income customers may be parking their primary wealth elsewhere while keeping a small account open just long enough to close it.

---

## Retention Strategy

Based on what the data actually shows:

**Go after single-product customers first.**
Build a cross-sell campaign targeted specifically at customers using only one product. The goal isn't revenue — it's switching cost. A customer with a savings account, a credit card, and a loan doesn't leave for a competitor easily.

**Create a regional retention program for high-churn, high-balance markets.**
The geography analysis identifies specific regions where customer losses are highest and average balances are above average. These markets need dedicated relationship managers or personalised outreach, not a generic email campaign.

**Investigate why active members are exiting.**
Run exit surveys or flag accounts that show high engagement metrics right before closure. If engaged customers are leaving, it's a signal issue — the bank is competing poorly on rates, service, or product value — and no loyalty programme fixes that. The product has to improve.

**Segment retention offers by age and tenure, not just balance.**
The 31–50 bracket exits at shorter tenures than the 50+ group. Early-tenure customers in this range should receive proactive outreach at the 2–3 year mark — not when they've already started the exit process.

**Re-evaluate the credit card as a retention tool.**
The data shows that having a credit card has a measurable but limited effect on churn. If the credit card isn't reducing exits significantly, it's functioning as a product, not a loyalty mechanism. Consider whether card benefits need to be restructured to create genuine stickiness.

**Build geographic + gender-specific offers carefully.**
The income ranking analysis shows gender-based salary differences vary by region. A blanket wealth management offer that works in one geography may be poorly calibrated for another. Segmented offers will outperform generic ones.
