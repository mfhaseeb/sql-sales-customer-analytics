# 🧩 Project: Customer Sales Analytics (SQL Portfolio Project)

## 📘 Overview
This SQL-based analytics project focuses on **understanding customer behavior** through data-driven insights.  
Using raw sales and customer data, I designed a reusable analytical model that classifies customers into segments such as **VIP**, **Regular**, and **New**, while also calculating key metrics like **average order value**, **monthly spend**, and **customer lifespan**.

---

## 🎯 Project Goals
- Analyze customer purchasing frequency, monetary value, and activity span.  
- Build a **data model** using joins between fact and dimension tables.  
- Segment customers based on **spending and retention behavior**.  
- Create a **SQL view** (`report_customers`) for easy dashboard integration.  
- Demonstrate advanced SQL techniques for real-world analytics.

---

## 🧠 Key SQL Techniques
- **Common Table Expressions (CTEs)** for modular query design  
- **Aggregation functions:** `SUM`, `COUNT`, `MAX`, `MIN`, `AVG`  
- **Conditional logic:** `CASE WHEN` for segment and age grouping  
- **Date functions:** `DATEDIFF`, `GETDATE()` for recency and lifespan analysis  
- **View creation:** `CREATE VIEW` for long-term data accessibility  

---

## 📊 Metrics & KPIs Calculated

| Metric | Description |
|--------|--------------|
| **Total Orders** | Count of unique orders per customer |
| **Total Sales** | Sum of all purchases made |
| **Lifespan** | Time between first and last order |
| **Recency** | Months since last order |
| **Average Order Value (AOV)** | `Total Sales / Total Orders` |
| **Average Monthly Spend** | `Total Sales / Lifespan` |
| **Customer Segment** | Classified as *VIP*, *Regular*, or *New* |

---

## 📈 Business Insights
- Identified high-value (VIP) customers who drive the majority of revenue.  
- Highlighted new and inactive customers for re-engagement strategies.  
- Provided age-based segmentation to align marketing efforts with demographics.  
- Designed an analytical dataset ready for visualization in **Power BI / Tableau**.
