--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".


select film_id, title, special_features	-- стоимость запроса: 90-92 (0,7 ms)
from film f
where special_features && '{"Behind the Scenes"}'
order by film_id


--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.


select film_id, title, special_features -- стоимость запроса: 90-92 (0,67 ms)
from film f
where special_features @> '{"Behind the Scenes"}'
order by film_id

select film_id, title, special_features -- стоимость запроса: 90-92 (0,71 ms)
from film f
where array['Behind the Scenes'] <@ special_features
order by film_id


--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.


with cte as -- стоимость запроса: 835-836 (9 ms)
(
	select film_id, title, special_features
	from film f
	where special_features && '{"Behind the Scenes"}'
	order by film_id
)
select r.customer_id,
	count(cte.film_id)
from rental r
join inventory i on r.inventory_id = i.inventory_id
join cte on i.film_id = cte.film_id
group by r.customer_id
order by r.customer_id


--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.


select r.customer_id, -- стоимость запроса: 789-791 (8,3 ms)
	count(k.film_id)
from rental r
join inventory i on r.inventory_id = i.inventory_id
join
(
	select film_id, title, special_features
	from film f
	where special_features && '{"Behind the Scenes"}'
	order by film_id
) k on i.film_id = k.film_id
group by r.customer_id
order by r.customer_id


--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления


create materialized view csms as
	select r.customer_id,
		count(k.film_id)
	from rental r
	join inventory i on r.inventory_id = i.inventory_id
	join
	(
		select film_id, title, special_features
		from film f
		where special_features && '{"Behind the Scenes"}'
		order by film_id
	) k on i.film_id = k.film_id
	group by r.customer_id
	order by r.customer_id

refresh materialized view csms


--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ скорости выполнения запросов
-- из предыдущих заданий и ответьте на вопросы:

--1. Каким оператором или функцией языка SQL, используемых при выполнении домашнего задания, 
--   поиск значения в массиве происходит быстрее
--2. какой вариант вычислений работает быстрее: 
--   с использованием CTE или с использованием подзапроса


-- 1. Поиск в заданиях 1 и 2 по стоимости и по времени примерно одинаковый.
-- И судя по explain analyze внутри оно выполняется примерно одинаково.
-- 2. Вариант с CTE по стоимости и по времени выполнения оказался больше
-- варианта с подзапросом. Но это в Linux, в Windows разницы не было.
-- Видимо, какие-то особенности реализации, потому что explain analyze
-- показал те же действия для соотвествующих запросов в обеих ОС.


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии

-- Откройте по ссылке SQL-запрос (https://letsdocode.ru/sql-hw5.sql).
-- - Сделайте explain analyze этого запроса.
-- - Основываясь на описании запроса, найдите узкие места и опишите их.
-- - Сравните с вашим запросом из основной части (если ваш запрос изначально укладывается в 15мс — отлично!).
-- - Сделайте построчное описание explain analyze на русском языке оптимизированного запроса. Описание строк в explain можно посмотреть по ссылке (https://use-the-index-luke.com/sql/explain-plan/postgresql/operations).


explain analyze
select distinct cu.first_name  || ' ' || cu.last_name as name,
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc

-- Согласно explain analyze, ProjectSet, формируемый во внутреннем подзапросе
-- главным образом сказывается на стоимости и времени выполнения всего запрос.
-- Очевидно, что это происходит потому, что unnest и full outer join генерируют
-- большой объем данных, на обработку которых тратится больше времени.
-- Остальные потенциально долгие операции, такие как: distinct, сравнение через like-оператор,
-- оконная функция и сортировка оказали гораздо меньшее влияние на итоговую стоимость.
-- Решение из задания 4 - более оптимально и выполняется быстрее, можно считать его
-- оптимизированным вариантом.
-- Сделаем построчное описание его explain analize.

explain analyze
select r.customer_id,
	count(k.film_id)
from rental r
join inventory i on r.inventory_id = i.inventory_id
join
(
	select film_id, title, special_features
	from film f
	where special_features && '{"Behind the Scenes"}'
	order by film_id
) k on i.film_id = k.film_id
group by r.customer_id
order by r.customer_id

--	сортировка результата обработки алгоритмом quicksort по ключу r.customer_id
--  Sort  (cost=789.62..791.12 rows=599 width=10) (actual time=8.250..8.280 rows=599 loops=1)
--	  Sort Key: r.customer_id
--	  Sort Method: quicksort  Memory: 53kB
--    
--    применение временной хэш-таблицы для группировки данных по ключу r.customer_id (не требует предварительной сортировки)
--	  ->  HashAggregate  (cost=756.00..761.99 rows=599 width=10) (actual time=8.039..8.120 rows=599 loops=1)
--	        Group Key: r.customer_id
--
--          загрузка кандидатов по inventory_id таблицы rental в хеш-таблицу, которая потом сопоставляется
--          с каждым кандидатом по inventory_id таблицы inventory
--	        ->  Hash Join  (cost=250.23..710.95 rows=9010 width=6) (actual time=2.179..6.562 rows=8608 loops=1)
--	              Hash Cond: (r.inventory_id = i.inventory_id)
--
--                просмотр таблицы rental
--	              ->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=6) (actual time=0.009..1.468 rows=16044 loops=1)
--
--                загрузка во временную хэш-таблицу
--	              ->  Hash  (cost=218.07..218.07 rows=2573 width=8) (actual time=2.158..2.158 rows=2471 loops=1)
--	                    Buckets: 4096  Batches: 1  Memory Usage: 129kB
--
--                      загрузка кандидатов по film_id таблицы inventory в хеш-таблицу, которая потом сопоставляется
--                      с каждым кандидатом по film_id подзапроса k
--	                    ->  Hash Join  (cost=104.35..218.07 rows=2573 width=8) (actual time=0.750..1.860 rows=2471 loops=1)
--	                          Hash Cond: (i.film_id = k.film_id)
--
--                            просмотр таблицы inventory
--	                          ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.005..0.380 rows=4581 loops=1)
--
--                            загрузка во временную хэш-таблицу
--	                          ->  Hash  (cost=97.63..97.63 rows=538 width=4) (actual time=0.739..0.739 rows=538 loops=1)
--	                                Buckets: 1024  Batches: 1  Memory Usage: 27kB
--
--                                  просмотр подзапроса k
--	                                ->  Subquery Scan on k  (cost=90.90..97.63 rows=538 width=4) (actual time=0.589..0.675 rows=538 loops=1)
--
--                                        сортировка выборки из таблицы film алгоритмом quicksort по ключу film_id
--	                                      ->  Sort  (cost=90.90..92.25 rows=538 width=552) (actual time=0.588..0.615 rows=538 loops=1)
--	                                            Sort Key: f.film_id
--	                                            Sort Method: quicksort  Memory: 50kB
--
--                                              просмотр и фильтрация таблицы film по заданному фильтру
--	                                            ->  Seq Scan on film f  (cost=0.00..66.50 rows=538 width=552) (actual time=0.009..0.501 rows=538 loops=1)
--	                                                  Filter: (special_features && '{"Behind the Scenes"}'::text[])
--	                                                  Rows Removed by Filter: 462
--
--  Планируемое время выполнения
--	Planning time: 0.500 ms
--
--  Фактическое время выполнения
--	Execution time: 8.387 ms


--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.


select p2.staff_id, f.film_id, f.title, p2.amount, p2.payment_date,
	c.last_name as customer_last_name, c.first_name as customer_first_name
from payment p2 
join customer c on p2.customer_id = c.customer_id
join rental r on p2.rental_id = r.rental_id
join inventory i on r.inventory_id = i.inventory_id
join film f on i.film_id = f.film_id
where p2.payment_id in (
	select payment_id
	from
	(
		select first_value(payment_id) over(partition by staff_id order by payment_date) as payment_id
		from payment p
	) k
	group by payment_id
)
order by staff_id


--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день


with store_rental as
(
	select store_id, rental_date, count
	from
	(
		select s.store_id,
			r.rental_date::date,
			count(i.film_id),
			row_number() over (partition by s.store_id order by count(i.film_id) desc) as rank
		from rental r
		join inventory i on r.inventory_id = i.inventory_id
		join staff s on r.staff_id = s.staff_id
		group by s.store_id, r.rental_date::date
	) rnlist
	where rank = 1
),
store_payments as
(
	select store_id, payment_date, sum
	from
	(
		select s.store_id,
			payment_date::date,
			sum(p.amount),
			row_number() over (partition by s.store_id order by sum(p.amount)) as rank
		from payment p
		join staff s on p.staff_id = s.staff_id
		group by s.store_id, payment_date::date
	) paylist
	where rank = 1
)
select sr.store_id, sr.rental_date, sr.count, sp.payment_date, sp.sum
from store_rental sr
join store_payments sp on sr.store_id = sp.store_id

