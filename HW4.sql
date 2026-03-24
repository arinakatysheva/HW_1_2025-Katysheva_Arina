
-- 1. Список всех клиентов

SELECT customer_id, first_name, last_name, email 
FROM customer

-- 2. Клиенты с именем Carolyn

SELECT first_name, last_name
FROM customer
WHERE first_name = 'Carolyn'


-- 3. Полное имя, содержит 'ary'

SELECT first_name || ' ' || last_name AS full_name
FROM customer
WHERE first_name ILIKE '%ary%'
   OR last_name ILIKE '%ary%'


-- 4. 20 самых крупных транзакций

SELECT * 
FROM payment
ORDER BY amount DESC
LIMIT 20


-- 5. Адреса всех магазинов (подзапрос)

SELECT address
FROM address
WHERE address_id IN (
    SELECT address_id FROM store
)


-- 6. День, месяц, день недели (Пн - 1)

SELECT 
    payment_id,
    EXTRACT(DAY FROM payment_date) AS day,
    EXTRACT(MONTH FROM payment_date) AS month,
    EXTRACT(ISODOW FROM payment_date) AS weekday
FROM payment


-- 7. Аренды за июнь 2005

SELECT
    customer_id,
    rental_date::date AS rental_date,
    staff_id
FROM rental
WHERE rental_date >= '2005-06-01' 
	AND rental_date < '2005-07-01'

-- 8. Фильмы после 2000 года длительностью 60–120 мин

SELECT title, description, length
FROM film
WHERE release_year > 2000
  AND length BETWEEN 60 AND 120
ORDER BY length DESC
LIMIT 20


-- 9. Платежи <4$ в апреле 2007

SELECT 
    payment_id,
    payment_date::date AS payment_date,
    amount
FROM payment
WHERE payment_date >= '2007-04-01'
  AND payment_date < '2007-05-01'
  AND amount <= 4
ORDER BY amount DESC, payment_date ASC



-- 10. Имена Jack, Bob, Sara и фамилия с 'p'

SELECT 
    first_name AS "Имя",
    last_name AS "Фамилия",
    customer_id AS "Идентификатор"
FROM customer
WHERE first_name IN ('Jack','Bob','Sara')
  AND last_name ILIKE '%p%'
ORDER BY customer_id


-- 11. Таблица студентов

DROP TABLE IF EXISTS students

CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    age INT NOT NULL,
    birth_date DATE NOT NULL,
    address TEXT NOT NULL
)

-- внесение студента с id > 50
INSERT INTO students (id, first_name, last_name, age, birth_date, address)
VALUES (60, 'Arina', 'Katysheva', 23, '2002-09-06', 'Moscow, str. Amurskaya, 8-80')

SELECT * FROM students

-- внесение нескольких студентов
INSERT INTO students (first_name, last_name, age, birth_date, address)
VALUES 
('Alexander','Osipov',22,'2003-10-14','Kazan, str. Baumana, 5-205'),
('Anna','Potemina',24,'2002-03-23','Saint-Petersburg, str. Rubinshteyna, 2-180'),
('Semen','Zhukov',21,'2004-07-02','Moscow, str. Pokrovka, 24-50')

SELECT * FROM students

-- удаление одного студента
DELETE FROM students 
WHERE id = (SELECT MIN(id) FROM students)

SELECT * FROM students

-- удаление таблицы
DROP TABLE students

-- попытка обращения к таблице
SELECT * FROM students


-- 12. Количество уникальных имен клиентов

SELECT COUNT(DISTINCT first_name) FROM customer


-- 13. 5 самых частых сумм платежей

SELECT 
    amount,
    MIN(payment_date::date) AS first_date,
    COUNT(*) AS count_payments,
    SUM(amount) AS total_sum
FROM payment
GROUP BY amount
ORDER BY count_payments DESC
LIMIT 5


-- 14. Количество ячеек в инвентаре 

SELECT store_id, COUNT(*) AS inventory_count
FROM inventory
GROUP BY store_id


-- 15. Адреса магазинов

SELECT 
	s.store_id,
	a.address
FROM store s
JOIN address a ON s.address_id = a.address_id


-- 16. Полные имена клиентов и сотрудников

SELECT first_name || ' ' || last_name AS full_name FROM customer
UNION ALL
SELECT first_name || ' ' || last_name FROM staff


-- 17. Имена клиентов, не совпадающие с именами сотрудников

SELECT first_name FROM customer
EXCEPT
SELECT first_name FROM staff


-- 18. Повтор задания 7

SELECT 
    customer_id,
    rental_date::date,
    staff_id
FROM rental
WHERE rental_date >= '2005-06-01' 
	AND rental_date < '2005-07-01' 



-- 19. Клиенты с 40+ оплат

SELECT 
    customer_id,
    COUNT(*) AS payment_count,
    ROUND(AVG(amount), 2) AS avg_payment
FROM payment
GROUP BY customer_id
HAVING COUNT(*) >= 40


-- 20. Актеры и фильмы

SELECT 
    a.actor_id,
    a.first_name || ' ' || a.last_name AS full_name,
    COUNT(fa.film_id) AS films_count
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
GROUP BY a.actor_id
ORDER BY films_count DESC


-- 21. Выручка по месяцам

WITH months AS (
    SELECT generate_series(
        DATE_TRUNC('month', MIN(rental_date)),
        DATE_TRUNC('month', MAX(rental_date)),
        INTERVAL '1 month'
    ) AS month
    FROM rental
)

SELECT 
    m.month::date AS rental_month,
    ROUND(COALESCE(SUM(p.amount), 0), 1) AS revenue
FROM months m
LEFT JOIN rental r 
    ON DATE_TRUNC('month', r.rental_date) = m.month
LEFT JOIN payment p 
    ON p.rental_id = r.rental_id
GROUP BY m.month
ORDER BY m.month


-- 22. Средний платеж по жанрам

SELECT 
    c.name AS genre,
    ROUND(AVG(p.amount),2) AS avg_payment
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON f.film_id = fc.film_id
JOIN inventory i ON i.film_id = f.film_id
JOIN rental r ON r.inventory_id = i.inventory_id
JOIN payment p ON p.rental_id = r.rental_id
GROUP BY c.name
HAVING COUNT(DISTINCT f.film_id) > 60
ORDER BY avg_payment desc


-- 23. Топ фильмов по субботам

SELECT 
    f.title,
    COUNT(*) AS cnt
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON f.film_id = i.film_id
WHERE EXTRACT(ISODOW FROM r.rental_date) = 6
GROUP BY f.title
ORDER BY cnt DESC, f.title
LIMIT 5


-- 24. Сумма, дата и день недели оплаты

SELECT 
    amount,
    payment_date::date,
    TO_CHAR(payment_date, 'Day')
FROM payment


-- 25. Категории фильмов по длительности

SELECT 
    CASE 
        WHEN f.length < 70 THEN 'Короткие'
        WHEN f.length < 130 THEN 'Средние'
        ELSE 'Длинные'
    END AS category,
    COUNT(DISTINCT f.film_id) AS films_count,
    COUNT(r.rental_id) AS rentals_count
FROM film f
JOIN inventory i ON i.film_id = f.film_id
JOIN rental r ON r.inventory_id = i.inventory_id
GROUP BY category


-- Создание таблицы weekly_revenue

DROP TABLE IF EXISTS weekly_revenue

CREATE TABLE weekly_revenue AS
SELECT
    EXTRACT(YEAR FROM rental_date) AS r_year,
    EXTRACT(WEEK FROM rental_date) AS r_week,
    SUM(amount) AS revenue
FROM rental r
LEFT JOIN payment p ON p.rental_id = r.rental_id
GROUP BY 1,2
ORDER BY 1,2

SELECT * FROM weekly_revenue


-- 26. Накопленная выручка

SELECT *,
	ROUND(SUM(revenue) OVER (ORDER BY r_year, r_week)) AS cumulative_revenue
FROM weekly_revenue


-- 27. Скользящая средняя

SELECT *,
	ROUND(SUM(revenue) OVER (ORDER BY r_year, r_week)) AS cumulative,
	ROUND(AVG(revenue) OVER (
    	ORDER BY r_year, r_week
    	ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
	)) AS moving_avg
FROM weekly_revenue


-- 28. Прирост недельной выручки

SELECT *,
	ROUND(SUM(revenue) OVER (ORDER BY r_year, r_week)) AS cumulative,
	ROUND(AVG(revenue) OVER (
    	ORDER BY r_year, r_week
    	ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
	)) AS moving_avg,
	ROUND(
    	(revenue - LAG(revenue) OVER (ORDER BY r_year, r_week))
    	/ NULLIF(LAG(revenue) OVER (ORDER BY r_year, r_week), 0) * 100, 2
	) AS growth_percent
FROM weekly_revenue










