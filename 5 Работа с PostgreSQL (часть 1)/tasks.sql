--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Cделайте запрос к таблице payment. 
--Пронумеруйте все продажи от 1 до N по дате продажи.


select payment_id,
	to_char(payment_date, 'YYYY-MM-DD HH:MI:SS.US') as payment_date,
	row_number() over (order by payment_date)
from payment p


--ЗАДАНИЕ №2
--Используя оконную функцию добавьте колонку с порядковым номером
--продажи для каждого покупателя,
--сортировка платежей должна быть по дате платежа.


select payment_id,
	to_char(payment_date, 'YYYY-MM-DD HH:MI:SS.US') as payment_date,
	customer_id,
	row_number() over (partition by customer_id order by payment_date)
from payment p


--ЗАДАНИЕ №3
--Для каждого пользователя посчитайте нарастающим итогом сумму всех его платежей,
--сортировка платежей должна быть по дате платежа.


select customer_id,
	payment_id,
	to_char(payment_date, 'YYYY-MM-DD HH:MI:SS.US') as payment_date,
	amount,
	sum(amount) over (partition by customer_id order by payment_date) as sum_amount
from payment p


--ЗАДАНИЕ №4
--Для каждого покупателя выведите данные о его последней оплате аренде.


select customer_id, payment_id, to_char(payment_date, 'YYYY-MM-DD HH:MI:SS.US') as payment_date, amount
from
(
	select customer_id,
		payment_id,
		payment_date,
		amount,
		row_number() over (partition by customer_id order by payment_date desc)
	from payment p
	order by customer_id
) k
where row_number = 1


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника магазина
--стоимость продажи из предыдущей строки со значением по умолчанию 0.0
--с сортировкой по дате продажи


select staff_id, payment_id, to_char(payment_date, 'YYYY-MM-DD HH:MI:SS.US') as payment_date, amount,
	lag(amount, 1, 0.) over (partition by staff_id order by payment_date) as last_amount
from payment p

--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за март 2007 года
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (дата без учета времени)
--с сортировкой по дате продажи


select staff_id,
	payment_date,
	sum_amount,
	sum(sum_amount) over (partition by staff_id order by payment_date)
from
(
	select staff_id,
		payment_date::date,
		sum(sum(amount)) over (partition by staff_id, payment_date::date) as sum_amount
	from payment p
	where date_trunc('month', payment_date) = '2007-03-01'
	group by staff_id, payment_date::date
) k

--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм


with cte1 as
(
	select r.customer_id, r.rental_date, f.rental_rate, c2.country_id
	from rental r
	join inventory i on r.inventory_id = i.inventory_id
	join film f on i.film_id = f.film_id
	join customer c on r.customer_id = c.customer_id
	join address a on c.address_id = a.address_id
	join city c2 on a.city_id = c2.city_id
),
cte2 as
(
	select country_id, customer_id,
		max(count(rental_rate)) over (partition by customer_id) as customer_max_count,
		max(sum(rental_rate)) over (partition by customer_id) as customer_max_rate,
		max(max(rental_date)) over (partition by customer_id) as customer_last_date
	from cte1
	group by country_id, customer_id
	order by country_id
),
cte3 as
(
	select c3.country,
		first_value(concat(c4.first_name, ' ', c4.last_name)) over (partition by cte2.country_id order by customer_max_count desc) as customer_max_count,
		first_value(concat(c4.first_name, ' ', c4.last_name)) over (partition by cte2.country_id order by customer_max_rate desc) as customer_max_rate,
		first_value(concat(c4.first_name, ' ', c4.last_name)) over (partition by cte2.country_id order by customer_last_date desc) as customer_last_date
	from cte2
	join country c3 on cte2.country_id = c3.country_id
	join customer c4 on cte2.customer_id = c4.customer_id
)
select *
from cte3
group by country, customer_max_count, customer_max_rate, customer_last_date
order by country
