use HW4;

-- add primary keys
alter table actor
add primary key(actor_id);

alter table address 
add primary key(address_id);

alter table category
add primary key(category_id);

alter table country
add primary key(country_id);

alter table city
add primary key(city_id);

alter table customer
add primary key(customer_id);

alter table film
add primary key(film_id);

alter table rental
add primary key(rental_id);

alter table staff
add primary key(staff_id);

alter table store
add primary key(store_id);

alter table inventory
drop primary key;

alter table inventory 
add primary key(inventory_id);

alter table language
add primary key(language_id);

alter table payment
add primary key(payment_id);

-- add foreign keys
alter table address
add foreign key(city_id)
references city(city_id);

alter table city
add foreign key(country_id)
references country(country_id);

alter table customer
add foreign key(store_id)
references store(store_id);

alter table customer
add foreign key(address_id)
references address(address_id);

alter table film
add foreign key(language_id)
references language(language_id);

alter table film_actor
add foreign key(actor_id)
references actor(actor_id);

alter table film_actor
add foreign key(film_id)
references film(film_id);

alter table rental
drop foreign key ren_in_fk;

alter table rental
add constraint ren_in_fk
foreign key rent(inventory_id)
references inventory(inventory_id)
on delete cascade;

alter table rental
add foreign key(customer_id)
references customer(customer_id);

alter table rental
add foreign key(staff_id)
references staff(staff_id);

alter table staff
add foreign key(address_id)
references address(address_id);

alter table staff
add foreign key(store_id)
references store(store_id);

alter table store
add foreign key(address_id)
references address(address_id);

alter table film_category
add foreign key(film_id)
references film(film_id);

alter table film_category
add foreign key(category_id)
references category(category_id);

alter table inventory
add foreign key(film_id)
references film(film_id);

alter table inventory
add foreign key(store_id)
references store(store_id);

alter table payment
add foreign key(customer_id)
references customer(customer_id);

alter table payment
add foreign key(staff_id)
references staff(staff_id);

alter table payment
add foreign key(rental_id)
references rental(rental_id);

-- add unique to needed attributes
-- duplicate entries in inventory id
delete from rental 
where inventory_id = 1886;
alter table rental
add constraint unique(inventory_id);

select inventory_id from rental where inventory_id = 1886;

alter table rental
modify rental_date varchar(50); 
alter table rental
add constraint unique (rental_date); -- duplicate entries in rental date

select rental_date from rental
where rental_date = '2011-07-27 08:14:34';

alter table rental
add constraint unique (customer_id); -- duplicate entries in customer id


select  rental_date, count(rental_date)
from rental
group by rental_date
having count(rental_date) > 1;

select inventory_id, count(inventory_id)
from rental
group by inventory_id
having count(inventory_id) >1;


-- add constraints for attribute values
alter table category
add constraint check_cat 
check (name in ('Animation', 'Comedy', 'Family', 
				'Foreign', 'Sci-Fi', 'Travel', 
                'Children', 'Drama', 'Horror', 
                'Action', 'Classics', 'Games', 
                'New', 'Documentary', 'Sports', 
                'Music'));

alter table film
add constraint check_feat
check(special_features in('Behind the Scenes', 'Commentaries', 'Deleted Scenes', 'Trailers'));

alter table rental
add constraint check_rent_date
check(rental_date between '2011-01-01 00:00:00' and '2011-12-31 23:59:59');


alter table rental
add constraint check_return_date
check(return_date between '2011-01-01 00:00:00' and '2012-12-31 23:59:59');

alter table payment
add constraint check_pay_date
check(payment_date between '2000-01-01 00:00:00' and '2012-12-31 23:59:59');

alter table staff
modify column active
tinyint(1) default false;

alter table film
add constraint check_duration
check(rental_duration between 2 and 8);

alter table film
add constraint check_rate
check(rental_rate between 0.99 and 6.99);

alter table film
add constraint check_length
check(length between 30 and 200);

alter table film
add constraint check_rating
check(rating in ('PG', 'G', 'NC-17', 'PG-13', 'R'));

alter table film
add constraint check_replacement
check (replacement_cost between 5.00 and 100.00);

alter table payment
add constraint check_amount
check(amount >= 0);



-- What is the average length of films in each category? List the results in alphabetic order of categories.
select c.name, avg(f.length) as average_length
from film f
inner join film_category fc on  fc.film_id = f.film_id -- inner joins to make connection between film and category
inner join category c on c.category_id = fc.category_id
group by c.name
order by c.name asc; -- puts the names of categories in alphabetical order

-- Which categories have the longest and shortest average film lengths?
select -- using subqueries to find the longest and shortest averages
	(select c.name
	from film f
	inner join film_category fc on  fc.film_id = f.film_id -- inner joins to make connection between film and category
	inner join category c on c.category_id = fc.category_id
	group by c.name, f.length
	order by f.length asc -- asc and limit 1 to find the shortest
	limit 1) as shortest_average,
	(select c.name
	from film f
	inner join film_category fc on  fc.film_id = f.film_id -- inner joins to make connection between film and category
	inner join category c on c.category_id = fc.category_id
	group by c.name, f.length
	order by f.length desc -- desc and limit 1 to find the longest
	limit 1) as longest_average;

-- Which customers have rented action but not comedy or classic movies?
select distinct c.first_name, c.last_name
from customer c
inner join rental r on r.customer_id = c.customer_id -- inner joins to connect customer to cateogory
inner join inventory i on i.inventory_id = r.inventory_id
inner join film f on f.film_id = i.film_id
inner join film_category fc on fc.film_id = f.film_id
inner join category cat on cat.category_id = fc.category_id
where cat.name = 'Action' -- shows customers who rented an action movie
	and c.customer_id not in( -- this subquery finds customers that rented classics and/or comedies and does not include them
		select c2.customer_id
		from customer c2
        inner join rental r2 on r2.customer_id = c2.customer_id
		inner join inventory i2 on i2.inventory_id = r2.inventory_id
		inner join film f2 on f2.film_id = i2.film_id
		inner join film_category fc2 on fc2.film_id = f2.film_id
		inner join category cat2 on cat2.category_id = fc2.category_id
		where cat2.name in ('Comedy', 'Classic')
        );

-- Which actor has appeared in the most English-language movies?
select 
	count(f.film_id) as film_count,  
	a.first_name as first_name, 
    a.last_name as last_name
from actor a
inner join film_actor fa on fa.actor_id = a.actor_id -- inner joins to connect actor to langauge
inner join film f on f.film_id = fa.film_id
inner join language l on l.language_id = f.language_id
where l.name = 'English' -- only english movies will be counted
group by a.actor_id, a.first_name, a.last_name
order by film_count DESC -- show the count descending to have the highest on top
limit 1; -- limit 1 to show only the top actor

-- How many distinct movies were rented for exactly 10 days from the store where Mike works?
select count(distinct f.film_id) as film_count -- counts the number films that pass the checks
from film f 
inner join inventory i on i.film_id = f.film_id -- inner joins to connect film to staff and store
inner join store on store.store_id = i.store_id
inner join staff sta on sta.store_id = store.store_id
where sta.first_name = 'Mike' and f.rental_duration = 10; -- check that the mike works at the store and that the rental is 10 days

-- Alphabetically list actors who appeared in the movie with the largest cast of actors.
select a.first_name, a.last_name, f.title as film_title
from actor a
inner join film_actor fa on fa.actor_id = a.actor_id -- make connection between actor and film
inner join film f on f.film_id = fa.film_id
where f.film_id = ( -- subquery to find the film with the most actors
    select f2.film_id
    from film f2
    inner join film_actor fa2 ON fa2.film_id = f2.film_id
    group by f2.film_id
    order by count(fa2.actor_id) desc -- puts the highest amount of actors on top
    limit 1 -- only considers the film with the most actors
)
order by a.first_name, a.last_name;
