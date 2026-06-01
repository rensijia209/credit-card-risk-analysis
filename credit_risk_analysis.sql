-- ==============================================
-- 信用卡用户违约风险分析 - 完整SQL脚本
-- 环境：SQLite / DBeaver
-- ==============================================

-- ==============================================
-- 步骤1：数据清洗，创建标准分析表 credit_clean
-- ==============================================
DROP TABLE IF EXISTS credit_clean;

CREATE TABLE credit_clean AS
SELECT DISTINCT
    ID,
    LIMIT_BAL,
    SEX,
    EDUCATION,
    MARRIAGE,
    AGE,
    PAY_0,
    PAY_2,
    PAY_3,
    BILL_AMT1,
    PAY_AMT1,
    "default.payment.next.month" AS is_default
FROM UCI_Credit_Card
WHERE
    ID IS NOT NULL
    AND LIMIT_BAL > 0
    AND AGE BETWEEN 18 AND 80;

-- 验证清洗后的数据（执行后能看到前5条数据即成功）
SELECT * FROM credit_clean LIMIT 5;

-- ==============================================
-- 步骤2：整体违约率统计
-- ==============================================
SELECT
    COUNT(*) AS total_users,
    SUM(is_default) AS default_users,
    ROUND(AVG(is_default) * 100, 2) AS default_rate
FROM credit_clean;

-- ==============================================
-- 步骤3：按性别分组统计违约率
-- ==============================================
SELECT
    CASE SEX WHEN 1 THEN '男' WHEN 2 THEN '女' END AS gender,
    COUNT(*) AS user_count,
    ROUND(AVG(is_default) * 100, 2) AS default_rate
FROM credit_clean
GROUP BY SEX;

-- ==============================================
-- 步骤4：按年龄分层统计违约率
-- ==============================================
SELECT
    CASE
        WHEN AGE < 30 THEN '20-29岁'
        WHEN AGE < 40 THEN '30-39岁'
        WHEN AGE < 50 THEN '40-49岁'
        ELSE '50岁以上'
    END AS age_group,
    COUNT(*) AS user_count,
    ROUND(AVG(is_default) * 100, 2) AS default_rate
FROM credit_clean
GROUP BY age_group
ORDER BY age_group;

-- ==============================================
-- 步骤5：窗口函数：年龄段违约率排名
-- ==============================================
SELECT
    age_group,
    default_rate,
    RANK() OVER(ORDER BY default_rate DESC) AS risk_rank
FROM (
    SELECT
        CASE WHEN AGE < 30 THEN '20-29'
             WHEN AGE < 40 THEN '30-39'
             WHEN AGE < 50 THEN '40-49'
             ELSE '50+' END AS age_group,
        ROUND(AVG(is_default) * 100, 2) AS default_rate
    FROM credit_clean
    GROUP BY age_group
) t;

-- ==============================================
-- 步骤6：高风险用户筛选（核心查询）
-- 条件：近期严重逾期(PAY_0 >= 2) + 低额度(LIMIT_BAL < 50000) + 已违约(is_default=1)
-- ==============================================
SELECT *
FROM credit_clean
WHERE
    PAY_0 >= 2
    AND LIMIT_BAL < 50000
    AND is_default = 1;
