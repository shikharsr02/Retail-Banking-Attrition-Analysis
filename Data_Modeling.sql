-- Imported csv data using Table wizard
-- DDL and DML is a better way to import data
-- (We will import this way in final draft)

SELECT * from `bank customer churn prediction`;

-- Creating a staging Table

CREATE TABLE Bank_Staging(
      `customer_id` int DEFAULT NULL,
  `credit_score` int DEFAULT NULL,
  `country` text,
  `gender` text,
  `age` int DEFAULT NULL,
  `tenure` int DEFAULT NULL,
  `balance` double DEFAULT NULL,
  `products_number` int DEFAULT NULL,
  `credit_card` int DEFAULT NULL,
  `active_member` int DEFAULT NULL,
  `estimated_salary` double DEFAULT NULL,
  `churn` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci

--Populating staging_table


insert into 
  bank_staging (
    customer_id, 
    credit_score, 
    country, 
    gender, 
    age, 
    tenure, 
    balance, 
    products_number, 
    credit_card, 
    active_member, 
    estimated_salary, 
    churn
  )
  SELECT DISTINCT customer_id, 
    credit_score, 
    country, 
    gender, 
    age, 
    tenure, 
    balance, 
    products_number, 
    credit_card, 
    active_member, 
    estimated_salary, 
    churn FROM `bank customer churn prediction` ;

-- 1. Create Customer Dimension (Demographics)
CREATE TABLE Dim_Customer (
    customer_id INT PRIMARY KEY,
    surname VARCHAR(100),
    gender VARCHAR(20),
    age INT,
    country VARCHAR(100)
);

ALTER TABLE dim_customer
DROP COLUMN surname;

-- 2. Create Account/Product Dimension (Operational Status)
CREATE TABLE Dim_Account (
    customer_id INT PRIMARY KEY,
    credit_card INT,          -- 1 or 0
    active_member INT,        -- 1 or 0
    products_number INT,      -- Number of bank products used
    estimated_salary DECIMAL(15, 2),
    FOREIGN KEY (customer_id) REFERENCES Dim_Customer(customer_id)
);

CREATE TABLE Fact_Churn (
    customer_id INT PRIMARY KEY,
    credit_score INT,
    balance DECIMAL(15, 2),
    tenure INT,               -- Number of years with bank
    churn INT,                -- 1 if exited, 0 if retained
    account_creation_date DATE, -- Synthetic field for Power BI
    exit_date DATE,            -- Synthetic field for Power BI
    FOREIGN KEY (customer_id) REFERENCES Dim_Customer(customer_id)
);


-- 1. Populate Customer Dimension
INSERT INTO Dim_Customer (customer_id, gender, age, country)
SELECT DISTINCT 
    customer_id, 
    gender, 
    age, 
    country
FROM Bank_Staging;

-- 2. Populate Account Dimension
INSERT INTO Dim_Account (customer_id, credit_card, active_member, products_number, estimated_salary)
SELECT DISTINCT 
    customer_id, 
    credit_card, 
    active_member, 
    products_number, 
    Estimated_Salary
FROM SELECT * FROM Bank_Staging;

-- 3. Populate Fact Table (Initial Load)
INSERT INTO Fact_Churn (customer_id, credit_score, balance, tenure, churn)
SELECT 
    Customer_Id, 
    Credit_Score, 
    Balance, 
    Tenure, 
    churn
FROM Bank_Staging;

SELECT * FROM fact_churn

-- 1. Ensure we are using the correct database
USE bank_churn; -- Replace with your actual database name

-- 2. Update the account_creation_date
UPDATE Fact_Churn
SET account_creation_date = DATE_SUB('2025-12-31', INTERVAL tenure YEAR);

-- 3. Update the exit_date for churned customers (where churn = 1)
UPDATE Fact_Churn
SET exit_date = DATE_ADD(account_creation_date, INTERVAL FLOOR(RAND() * (tenure * 365)) DAY)
WHERE churn = 1;

-- 4. CRITICAL: Commit the transaction so Power BI can see the data
COMMIT;
