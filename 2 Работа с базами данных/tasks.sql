--=============== МОДУЛЬ 2. РАБОТА С БАЗАМИ ДАННЫХ =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите уникальные названия регионов из таблицы адресов


select distinct district from address;


--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания, чтобы запрос выводил только те регионы, 
--названия которых начинаются на "K" и заканчиваются на "a", и названия не содержат пробелов


-- вариант 1:
select distinct district from address where district like 'K%a' and not district like '% %';
-- вариант 2:
select distinct district from address where district like 'K%a' and position(' ' in district) = 0;


--ЗАДАНИЕ №3
--Получите из таблицы платежей за прокат фильмов информацию по платежам, которые выполнялись 
--в промежуток с 17 марта 2007 года по 19 марта 2007 года включительно, 
--и стоимость которых превышает 1.00.
--Платежи нужно отсортировать по дате платежа.


select * from payment where payment_date between '2007-03-17' and '2007-03-19' and amount > 1.00 order by payment_date;


--ЗАДАНИЕ №4
-- Выведите информацию о 10-ти последних платежах за прокат фильмов.


select * from payment order by payment_date desc limit 10;


--ЗАДАНИЕ №5
--Выведите следующую информацию по покупателям:
--  1. Фамилия и имя (в одной колонке через пробел)
--  2. Электронная почта
--  3. Длину значения поля email
--  4. Дату последнего обновления записи о покупателе (без времени)
--Каждой колонке задайте наименование на русском языке.


select concat(last_name, ' ', first_name) as "Фамилия и имя",
	email as "Электронная почта",
	length(email) as "Длина поля email",
	last_update::date as "Дата последнего обновления"
from customer;


--ЗАДАНИЕ №6
--Выведите одним запросом активных покупателей, имена которых Kelly или Willie.
--Все буквы в фамилии и имени из нижнего регистра должны быть переведены в высокий регистр.


select upper(first_name) as "Имя", upper(last_name) as "Фамилия" from customer
where activebool and (first_name = 'Kelly' or first_name = 'Willie');


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите одним запросом информацию о фильмах, у которых рейтинг "R" 
--и стоимость аренды указана от 0.00 до 3.00 включительно, 
--а также фильмы c рейтингом "PG-13" и стоимостью аренды больше или равной 4.00.


select * from film
where rating = 'R' and rental_rate between 0.00 and 3.00 or
	rating = 'PG-13' and rental_rate >= 4.00;


--ЗАДАНИЕ №2
--Получите информацию о трёх фильмах с самым длинным описанием фильма.


select * from film order by length(description) desc limit 3;


--ЗАДАНИЕ №3
-- Выведите Email каждого покупателя, разделив значение Email на 2 отдельных колонки:
--в первой колонке должно быть значение, указанное до @, 
--во второй колонке должно быть значение, указанное после @.


select split_part(email, '@', 1) as "Получатель", split_part(email, '@', 2) as "Домен" from customer;


--ЗАДАНИЕ №4
--Доработайте запрос из предыдущего задания, скорректируйте значения в новых колонках: 
--первая буква должна быть заглавной, остальные строчными.


-- вариант 1:
select concat(upper(substring(split_part(email, '@', 1) from 1 for 1)), lower(substring(split_part(email, '@', 1) from 2))) as "Получатель",
	concat(upper(substring(split_part(email, '@', 2) from 1 for 1)), lower(substring(split_part(email, '@', 2) from 2))) as "Домен"
from customer;
-- вариант 2:
select upper(left(split_part(email, '@', 1), 1)) || lower(right(split_part(email, '@', 1), -1)) as "Получатель",
	upper(left(split_part(email, '@', 2), 1)) || lower(right(split_part(email, '@', 2), -1)) as "Домен"
from customer;

