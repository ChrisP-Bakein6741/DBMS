use class_examples;


-- part 1: tables have been imported -- 
-- define the primary keys for each of the imported tables -- 
alter table chefs
add primary key(chefid);

alter table foods
add primary key(foodid);

alter table restaurants
add primary key(restid);

-- make the connection between the entities with the relationships of serves and works using forgien keys -- 

alter table serves
add constraint fk_serves_rest
foreign key(restid)
references restaurants(restid);

alter table serves
add constraint fk_serves_food
foreign key(foodid)
references foods(foodid);

alter table works
add constraint fk_works_chefs
foreign key(chefid)
references chefs(chefid);

alter table works
add constraint fk_works_restaurants
foreign key(restid)
references restaurants(restid);

-- Part 2 -- 
-- #1 Average price of foods at each restaurant --
select r.name as restaurant_name, -- here I added a name for the r.name column that will be viewed
	avg(f.price) as average_price -- find the average of the food price -- 
from restaurants r
inner join serves s on r.restid = s.restid -- inner join for the relation of serves and restaurants via the primary key --
inner join foods f on s.foodid = f.foodid -- inner join for foods and serves via primary key -- 
group by r.restid, r.name -- grouped the visual table by restid and name --
order by average_price desc; -- put the results from largest to smallest--


-- #2 Max food price at each restaurant -- 
-- Works by finding the max price from the foods entity, then ordering them from largest to smallest --
-- The inner join statements help to connect the restaurant entity to the food entity -- 
select r.name as restaurant_name, 
	max(f.price) as max_price 
from restaurants r
inner join serves s on r.restid = s.restid 
inner join foods f on s.foodid = f.foodid 
group by r.restid, r.name
order by max_price desc;

-- #3 Count of different food types served at each restaurant --
-- Works by using the count statement to find out how many foods there are --
-- Then inner join statements connect restaurants and foods --
select r.name as restaurant_name,
	count(f.foodid) as foods_served
from restaurants r
inner join serves s on r.restid = s.restid
inner join foods f on s.foodid = f.foodid
group by r.restid, r.name;

-- #4 Average price of foods served by each chef -- 
-- This query first finds the average price for the foods --
-- Then I used 4 inner join statements in order to connect the chefs entity to the foods entity making use of works and serves--
select c.name as chef_name,
	avg(f.price) as average_price
from chefs c 
inner join works w on c.chefid = w.chefid
inner join restaurants r on r.restid = w.restid
inner join serves s on r.restid = s.restid
inner join foods f on f.foodid = s.foodid
group by c.chefid,c.name
order by average_price desc;

-- #5 Restaurant with the highest food price -- 
-- finds the max food price from the food entity -- 
-- inner join statements connect the restaurants to the foods -- 
-- to make it only 1 restaurant with the highest price I used the order by and limit statement -- 
select r.name as restaurant_name,
	max(f.price) as price
from restaurants r
inner join serves s on r.restid = s.restid
inner join foods f on s.foodid = f.foodid
group by r.restid, r.name
order by price desc
limit 1;



