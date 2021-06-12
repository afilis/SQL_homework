--=============== ЛАБОРАТОРНАЯ РАБОТА =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public

--===== Основные задания =====
--1. Рассчитайте совокупный доход всех магазинов на каждую дату.


select
	p.payment_date::date as date,
	sum(p.amount) as sum_amount
from payment p
group by p.payment_date::date
order by p.payment_date::date


--2. Выведите наиболее и наименее востребованные жанры
--(те, которые арендовали наибольшее/наименьшее количество раз),
--число их общих продаж и сумму дохода/


with cte as
(
	select c.name as cat,
		count(r.rental_id) as cnt,
		sum(p.amount) as amount,
		row_number() over (order by count(r.rental_id)) as rank
	from category c
	left join film_category fc on c.category_id = fc.category_id
	left join inventory i on fc.film_id = i.film_id
	left join rental r on i.inventory_id = r.inventory_id
	left join payment p on r.rental_id = p.rental_id
	group by c.name
	order by count(r.rental_id)
)
select cat, cnt, amount
from cte
where rank = 1 or rank = (select count(*) from cte)


--3. Какова средняя арендная ставка для каждого жанра?
--(упорядочить по убыванию, среднее значение округлить до сотых)


select c.name as cat,
	round(avg(f.rental_rate), 2) as avg_rental_rate
from category c
left join film_category fc on c.category_id = fc.category_id
left join film f on fc.film_id = f.film_id
group by c.name
order by round(avg(f.rental_rate), 2) desc


--===== Дополнительные задания =====
--4. Составить список из 5 самых дорогих клиентов (арендовавших фильмы с 10 по 13 апреля).
--формат списка:
--'Имя_клиента Фамилия_клиента email address is: e-mail_клиента'


select concat(c.first_name, ' ', c.last_name, ' email address is: ', c.email)
from
(
	select customer_id,
		sum(amount)
	from payment p
	where payment_date between '2007-04-10' and '2007-04-13'
	group by customer_id
	order by sum(amount) desc
	limit 5
) k
join customer c on k.customer_id = c.customer_id
order by sum desc


--5. Сколько арендованных фильмов было возвращено в срок, до срока возврата и после, выведите максимальную разницу со сроком


with cte as
(
	select date_part('day', r.return_date - r.rental_date) - f.rental_duration as diff
	from rental r
	join inventory i on r.inventory_id = i.inventory_id
	join film f on i.film_id = f.film_id
	where r.return_date is not null
)
select 'Раньше срока' as type,
	count(diff) filter (where diff < 0) as count,
	max(abs(diff)) filter (where diff < 0) as max_diff
from cte
union
select 'В срок' as type,
	count(diff) filter (where diff = 0) as count,
	0 as max_diff
from cte
union
select 'После срока' as type,
	count(diff) filter (where diff > 0) as count,
	max(diff) filter (where diff > 0) as max_diff
from cte
