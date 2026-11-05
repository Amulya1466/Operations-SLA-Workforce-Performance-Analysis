select* from Operations

--Total records
select 
count(*) as total_records
from Operations;

--Top 10 records
select top 10*
from Operations;

--DUplicates
select task_ID,
count(*) as Duplicates
from Operations
group by task_ID
Having count(*) >1;

SELECT *
FROM dbo.Operations
WHERE Task_ID IN (
    'TASK100275',
    'TASK100582',
    'TASK100819',
    'TASK101133',
    'TASK102125',
    'TASK102161',
    'TASK102750',
    'TASK103421',
    'TASK104368',
    'TASK104837'
)
ORDER BY Task_ID;

--missing values
SELECT
    SUM(CASE WHEN Task_ID IS NULL THEN 1 ELSE 0 END) AS Missing_Task_ID,
    SUM(CASE WHEN Employee_ID IS NULL THEN 1 ELSE 0 END) AS Missing_Employee_ID,
    SUM(CASE WHEN Received_Date IS NULL THEN 1 ELSE 0 END) AS Missing_Received_Date,
    SUM(CASE WHEN Status IS NULL THEN 1 ELSE 0 END) AS Missing_Status
FROM dbo.Operations;

--Status distributuion

SELECT
    Status,
    COUNT(*) AS Total_Tasks
FROM dbo.Operations
GROUP BY Status
ORDER BY Total_Tasks DESC;

--Team level distribution 
select team,
count(*) as Total_tasks
from Operations
group by team 
order by Total_tasks Desc;

--Total records managed by each team and Employees
SELECT
    Team,
    COUNT(*) AS Total_Records,
    COUNT(DISTINCT Task_ID) AS Unique_Tasks,
    COUNT(DISTINCT Employee_ID) AS Employees
FROM Operations
GROUP BY Team
ORDER BY Total_Records DESC;

--number of tasks completed and pending 
SELECT
    COUNT(*) AS Total_Records,
    COUNT(DISTINCT Task_ID) AS Unique_Tasks,
    SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) AS Completed_Tasks,
    SUM(CASE WHEN Status = 'Pending' THEN 1 ELSE 0 END) AS Pending_Tasks
FROM Operations;

--average TAT 
SELECT
    Team,
    ROUND(AVG(Actual_TAT_Hours), 2) AS Average_TAT_Hours
FROM Operations
WHERE Status = 'Completed'
GROUP BY Team
ORDER BY Average_TAT_Hours ASC;

--Tasks met SLA and Breached
SELECT
    SUM(CASE
        WHEN Status = 'Completed'
         AND Actual_TAT_Hours <= SLA_Hours
        THEN 1 ELSE 0
    END) AS SLA_Met_Tasks,

    SUM(CASE
        WHEN Status = 'Completed'
         AND Actual_TAT_Hours > SLA_Hours
        THEN 1 ELSE 0
    END) AS SLA_Breached_Tasks
FROM Operations;

-- SLA Compliance
SELECT
    COUNT(CASE
        WHEN Status = 'Completed' THEN 1
    END) AS Completed_Tasks,

    SUM(CASE
        WHEN Status = 'Completed'
         AND Actual_TAT_Hours <= SLA_Hours
        THEN 1 ELSE 0
    END) AS SLA_Met_Tasks,

    ROUND(
        100.0 * SUM(CASE
            WHEN Status = 'Completed'
             AND Actual_TAT_Hours <= SLA_Hours
            THEN 1 ELSE 0
        END)
        / NULLIF(COUNT(CASE
            WHEN Status = 'Completed' THEN 1
        END), 0),
        2
    ) AS SLA_Compliance_Percentage
FROM Operations;

--Team performance analysis
SELECT
    Team,
    COUNT(*) AS Total_Records,

    SUM(CASE
        WHEN Status = 'Completed' THEN 1 ELSE 0
    END) AS Completed_Tasks,

    SUM(CASE
        WHEN Status = 'Completed'
         AND Actual_TAT_Hours <= SLA_Hours
        THEN 1 ELSE 0
    END) AS SLA_Met,

    SUM(CASE
        WHEN Status = 'Completed'
         AND Actual_TAT_Hours > SLA_Hours
        THEN 1 ELSE 0
    END) AS SLA_Breached,

    ROUND(AVG(CASE
        WHEN Status = 'Completed' THEN Actual_TAT_Hours
    END), 2) AS Average_TAT

FROM Operations
GROUP BY Team
ORDER BY SLA_Breached DESC;

--Which teams have the lowest SLA compliance?
WITH Team_SLA AS
(
    SELECT
        Team,
        COUNT(*) AS Total_Records,

        SUM(CASE
            WHEN Status = 'Completed' THEN 1
            ELSE 0
        END) AS Completed_Tasks,

        SUM(CASE
            WHEN Status = 'Completed'
             AND Actual_TAT_Hours <= SLA_Hours
            THEN 1 ELSE 0
        END) AS SLA_Met,

        SUM(CASE
            WHEN Status = 'Completed'
             AND Actual_TAT_Hours > SLA_Hours
            THEN 1 ELSE 0
        END) AS SLA_Breached

    FROM dbo.Operations
    GROUP BY Team
)

SELECT
    Team,
    Completed_Tasks,
    SLA_Met,
    SLA_Breached,

    ROUND(
        SLA_Met * 100.0 / NULLIF(Completed_Tasks, 0),
        2
    ) AS SLA_Compliance_Percentage

FROM Team_SLA
ORDER BY SLA_Compliance_Percentage ASC;

--Employee productivity ranking
SELECT
    Employee_ID,
    COUNT(*) AS Completed_Tasks,

    RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS Productivity_Rank

FROM dbo.Operations
WHERE Status = 'Completed'
GROUP BY Employee_ID
ORDER BY Productivity_Rank;

--Employee SLA performance
SELECT
    Employee_ID,

    COUNT(*) AS Completed_Tasks,

    SUM(CASE
        WHEN Actual_TAT_Hours <= SLA_Hours
        THEN 1 ELSE 0
    END) AS SLA_Met,

    ROUND(
        SUM(CASE
            WHEN Actual_TAT_Hours <= SLA_Hours
            THEN 100.0 ELSE 0
        END) / COUNT(*),
        2
    ) AS SLA_Compliance_Percentage

FROM Operations
WHERE Status = 'Completed'
GROUP BY Employee_ID
ORDER BY SLA_Compliance_Percentage DESC;

--What is the overall operational performance?
USE SQL;
GO

CREATE VIEW vw_Operations_Summary
AS
SELECT
    COUNT(*) AS Total_Records,

    COUNT(DISTINCT Task_ID) AS Unique_Tasks,

    SUM(CASE
        WHEN Status = 'Completed' THEN 1
        ELSE 0
    END) AS Completed_Tasks,

    SUM(CASE
        WHEN Status = 'Pending' THEN 1
        ELSE 0
    END) AS Pending_Tasks,

    SUM(CASE
        WHEN Status = 'Completed'
         AND Actual_TAT_Hours <= SLA_Hours
        THEN 1 ELSE 0
    END) AS SLA_Met,

    SUM(CASE
        WHEN Status = 'Completed'
         AND Actual_TAT_Hours > SLA_Hours
        THEN 1 ELSE 0
    END) AS SLA_Breached

FROM Operations;
GO


USE SQL
GO

SELECT *
FROM vw_Operations_Summary;

--Team Performance View

CREATE VIEW vw_Team_Performance
AS
SELECT
    Team,

    COUNT(*) AS Total_Records,

    COUNT(DISTINCT Task_ID) AS Unique_Tasks,

    COUNT(DISTINCT Employee_ID) AS Total_Employees,

    SUM(CASE
        WHEN Status = 'Completed' THEN 1
        ELSE 0
    END) AS Completed_Tasks,

    SUM(CASE
        WHEN Status = 'Completed'
         AND Actual_TAT_Hours <= SLA_Hours
        THEN 1 ELSE 0
    END) AS SLA_Met,

    SUM(CASE
        WHEN Status = 'Completed'
         AND Actual_TAT_Hours > SLA_Hours
        THEN 1 ELSE 0
    END) AS SLA_Breached,

    ROUND(AVG(CASE
        WHEN Status = 'Completed'
        THEN Actual_TAT_Hours
    END), 2) AS Average_TAT_Hours,

    ROUND(
        100.0 * SUM(CASE
            WHEN Status = 'Completed'
             AND Actual_TAT_Hours <= SLA_Hours
            THEN 1 ELSE 0
        END)
        / NULLIF(SUM(CASE
            WHEN Status = 'Completed' THEN 1
            ELSE 0
        END), 0), 2
    ) AS SLA_Compliance_Percentage

FROM Operations
GROUP BY Team;
GO

--test
SELECT *
FROM vw_Team_Performance
ORDER BY SLA_Compliance_Percentage DESC;

--Employee Productivity View
CREATE VIEW vw_Employee_Performance
AS
SELECT
    Employee_ID,

    Team,

    COUNT(*) AS Total_Records,

    SUM(CASE
        WHEN Status = 'Completed' THEN 1
        ELSE 0
    END) AS Completed_Tasks,

    SUM(CASE
        WHEN Status = 'Completed'
         AND Actual_TAT_Hours <= SLA_Hours
        THEN 1 ELSE 0
    END) AS SLA_Met,

    ROUND(AVG(CASE
        WHEN Status = 'Completed'
        THEN Actual_TAT_Hours
    END), 2) AS Average_TAT_Hours

FROM Operations
GROUP BY Employee_ID, Team;
GO

--Top 5 in productivity Ranked
SELECT *,
    RANK() OVER (
        ORDER BY Completed_Tasks DESC
    ) AS Productivity_Rank
FROM vw_Employee_Performance
ORDER BY Productivity_Rank;


SELECT TOP 5 *
FROM vw_Operations_Summary;

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Operations';

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'vw_Operations_Summary';

SELECT DISTINCT Status
FROM Operations;

SELECT DISTINCT SLA_status
FROM Operations;

--Average TAT for each team

SELECT
    Team,
    COUNT(DISTINCT Task_ID) AS Total_Tasks,
    COUNT(DISTINCT CASE
        WHEN Status = 'Completed'
        THEN Task_ID END) AS Completed_Tasks,
    COUNT(DISTINCT CASE
        WHEN Status = 'Pending'
        THEN Task_ID END) AS Pending_Tasks,
    COUNT(DISTINCT CASE
        WHEN SLA_status = 'Breached'
        THEN Task_ID END) AS SLA_Breached,
    AVG(CAST(Actual_TAT_Hours AS FLOAT)) AS Average_TAT
FROM Operations
GROUP BY Team
ORDER BY Team;

--priority wise SLA met and breached 
SELECT
    Priority,
    SLA_Hours,
    COUNT(DISTINCT Task_ID) AS Total_Tasks,
    COUNT(DISTINCT CASE
        WHEN SLA_status = 'Met'
        THEN Task_ID END) AS SLA_Met,
    COUNT(DISTINCT CASE
        WHEN SLA_status = 'Breached'
        THEN Task_ID END) AS SLA_Breached
FROM Operations
GROUP BY
    Priority,
    SLA_Hours
ORDER BY
    Priority,
    SLA_Hours;


--count of pending tasks
    SELECT
    COALESCE(SLA_status, 'NULL') AS SLA_Status,
    COUNT(DISTINCT Task_ID) AS Task_Count
FROM Operations
WHERE SLA_status IS NULL
   OR SLA_status NOT IN ('Met', 'Breached')
GROUP BY SLA_status;