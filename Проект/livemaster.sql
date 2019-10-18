DROP DATABASE IF EXISTS db_livemaster;
CREATE DATABASE db_livemaster DEFAULT CHARACTER SET utf8 COLLATE utf8_bin ;
USE db_livemaster;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id SERIAL,
  username VARCHAR(45) NOT NULL UNIQUE,
  email VARCHAR(120) NOT NULL UNIQUE,
  is_seller ENUM ('no', 'yes') NOT NULL,
  PRIMARY KEY (id));
  
DROP TABLE IF EXISTS sellers;
CREATE TABLE sellers (
  id SERIAL,
  shop_name VARCHAR(45),
  contact_address VARCHAR(255) NULL,
  is_user BIGINT UNSIGNED NOT NULL,
  FOREIGN KEY (is_user) REFERENCES users(id)
  ON UPDATE CASCADE

  , -- чтобы быть продавцом, нужно быть юзером. Но можно удалить магазин и остаться юзером
  PRIMARY KEY (id, is_user)); -- у одного юзера может быть 2 продавца-магазина. У юзера свой id, у продавца ставится свой id. Поэтому ключом идет пара
  
DROP TABLE IF EXISTS users_profiles;
CREATE TABLE users_profiles (
	user_id SERIAL,
    real_name VARCHAR(100), -- Указывать своё настоящее имя на сайте необязательно, поэтому будет храниться вместе имя+фамилия, все равно поиск/сортировка по этому параметру недоступны на сайте (продавцов ищут по названию магазина) 
    gender ENUM('male', 'female') NULL,
    birthday DATE NULL,
	photo_id BIGINT UNSIGNED NULL,
    created_at DATETIME DEFAULT NOW(),
    hometown VARCHAR(100) NULL,
    shipping_address VARCHAR(255) NULL, -- Юзер может ввести один раз, или вводить при каждом заказе 
	telephone_number BIGINT NULL,
	interests VARCHAR(45) NULL,
    username VARCHAR(45) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) 
    	ON UPDATE CASCADE
    	ON DELETE restrict
        ,
	FOREIGN KEY (username) REFERENCES users(username) 
    	ON UPDATE CASCADE
    	ON DELETE restrict
        ,
	PRIMARY KEY (user_id));
    
DROP TABLE IF EXISTS users_subscribed_tos;
CREATE TABLE users_subscribed_tos(  -- Можно подписаться на мастера, когда он разместит новую работу, пользователь получит сообщение
	user_id BIGINT UNSIGNED NOT NULL,
	seller_id BIGINT UNSIGNED NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (seller_id) REFERENCES sellers(id),
    PRIMARY KEY (user_id, seller_id)); -- чтобы не было 2 записей о пользователе и мастере 
  
  
DROP TABLE IF EXISTS products_categories;
CREATE TABLE products_categories (
 `category_id` SERIAL,
 category_name VARCHAR(45),
PRIMARY KEY (`category_id`));

DROP TABLE IF EXISTS products;
CREATE TABLE products ( -- каталог общий для всех, под товаром подписывают магазин продавца
  `id` SERIAL,
  seller_id BIGINT UNSIGNED NOT NULL,
  `product_name` VARCHAR(45) NOT NULL,
  `price` DECIMAL(13,2) NOT NULL,
  `category` BIGINT UNSIGNED NOT NULL,
  `customisation` ENUM('no', 'yes') NOT NULL, -- некоторые изделия мастера могут по запросу перекрасить/изготовить такое же, но бордовое и т.п.
  `shipped` ENUM('no', 'yes') NOT NULL,
  FOREIGN KEY (seller_id) REFERENCES sellers(id)
  ON UPDATE CASCADE
  ,
  FOREIGN KEY (category) REFERENCES products_categories(category_id)
  ,
  PRIMARY KEY (`id`));
  

DROP TABLE IF EXISTS seasonal_promotions;
CREATE TABLE `seasonal_promotions` (
  `id` SERIAL,
  `season` ENUM('winter', 'spring', 'summer', 'autumn') NOT NULL,
  `starts` DATETIME NOT NULL,
  `ends` DATETIME NOT NULL,
  is_promoted BIGINT UNSIGNED NOT NULL, -- продвигаемая категория, например зимой - шарфы. Товары по одному не продвигаются на сайте
  FOREIGN KEY (is_promoted) REFERENCES products_categories(category_id) 
    	ON UPDATE CASCADE 
        ,
  PRIMARY KEY (`id`));


CREATE TABLE `order` (
`id` SERIAL,
`ordered_products` JSON NOT NULL,
`ship_to` BIGINT UNSIGNED NOT NULL,
`shipped_by` BIGINT UNSIGNED NOT NULL,
-- ship_to_address VARCHAR(255) NOT NULL, -- сделать бы дефолт = юзер форен ки, иначе можно ввести
`payment_method` ENUM('credit_card', 'paypal', 'cash') NOT NULL,
`paid` ENUM('no', 'yes') NOT NULL,
FOREIGN KEY (ship_to) REFERENCES users(id)
	ON DELETE RESTRICT
	, -- если юзер удалится, его история заказов все равно сохранится
FOREIGN KEY (shipped_by) REFERENCES sellers(id)
	ON DELETE RESTRICT
	, -- магазин тоже можно удалить, история заказов остается
-- FOREIGN KEY (ship_to_address) REFERENCES profiles(shipping_address)
	-- ON UPDATE CASCADE 
	-- ON DELETE RESTRICT
	-- ,
  PRIMARY KEY (`id`));
  
 CREATE TABLE `contests` (
  `id` SERIAL,
  `starts` DATETIME NOT NULL,
  `finishes` DATETIME NOT NULL,
  `winner` BIGINT UNSIGNED,
  `prize` BIGINT UNSIGNED,
  FOREIGN KEY (winner) REFERENCES users(id) 
    	ON DELETE restrict
	,
	FOREIGN KEY (prize) REFERENCES products(id) 
    	ON DELETE restrict
	,
  PRIMARY KEY (`id`));
  
  CREATE TABLE `academy` (
  `id` SERIAL,
  `activity_type`  ENUM('article', 'vebinar', 'workshop') NOT NULL,
  `date` DATETIME NOT NULL,
  `count` INT NOT NULL,
  `author` BIGINT UNSIGNED,
  FOREIGN KEY (author) REFERENCES sellers(id) 
    	ON DELETE restrict
	,
  PRIMARY KEY (`id`));
  
  
  -- добавляем данные таблиц

INSERT INTO `users` (`username`, `email`, `is_seller`) VALUES ('black', 'ivansusnov@gmail.com', 'no'),
('fluffanora', 'norakadi@mail.ru', 'no'),
('elenahelnova', 'elenahelnova@gmail.com', 'yes'),
('sorenmark', 'sorenmark@dk.com', 'yes'),
('helgadutch', 'helgadutch@mail.ru', 'no'),
('rovanis', 'vovaiut@mail.ru', 'no'),
('joaif', 'fdskw@mail.ru', 'yes'),
('josephi', 'sofagiao@gmail.com', 'no'),
('fnpow', 'ignis@gmail.com', 'yes'),
('faseroava', 'fasarina@mail.ru', 'no'),
('arinakrav', 'arinakrav@mail.ru', 'no'),
('susfor', 'susfor@gmail.com', 'no'),
('galinauslov', 'galinagia@dk.com', 'yes'),
('alinak', 'alinakobv@mail.ru', 'yes'),
('albine', 'alibeurk@mail.ru', 'no'),
('marinetgs', 'tusklovamarina@mail.ru', 'yes'),
('ghoston', 'dfieafzl@gmail.com', 'yes'),
('adryy', 'andreygfisov@gmail.com', 'yes'),
('rubin', 'emanuilova@mail.ru', 'no'),
('erenarara', 'lixajuisv@mail.ru', 'no'),
('antoninaroabg', 'antoninafsova@gmail.com', 'no'),
('markspence', 'markpeterov@dk.com', 'no'),
('tamata', 'tamataa@mail.ru', 'no'),
('gfoev', 'ghosttown@mail.ru', 'no'),
('blacklamp', 'lampada@mail.ru', 'yes'),
('trousersformen', 'alinajutova@gmail.com', 'yes'),
('moresea', 'seagao@gmail.com', 'yes'),
('ilovewaffles', 'waffletown@gmail.com', 'yes'),
('beconsquare', 'beconsquare@mail.ru', 'yes'),
('water', 'deepwaters@mail.ru', 'yes'),
('dickturnip', 'richardbach@gmail.com', 'yes'),
('lovependants', 'faoewoiv@dk.com', 'yes'),
('tigers', 'ilovetigersforv@mail.ru', 'yes'),
('moscows', 'jeansmoscow@mail.ru', 'yes'),
('aad', 'adamapf@mail.ru', 'yes'),
('mapsfor', 'makemapsforpeople@gmail.com', 'yes'),
('livelife', 'leavesdotdot@gmail.com', 'yes'),
('kasanova', 'clothesformenxxl@mail.ru', 'yes'),
('sisilia', 'sillina@gmail.com', 'yes'),
('rerena', 'irinamars@gmail.com', 'yes'),
('fontanov', 'fontanov@mail.ru', 'yes'),
('tamofa', 'faranfaf@mail.ru', 'yes'),
('faonfapfdsg', 'agnisfatuum@gmail.com', 'yes'),
('memenotmoir', 'moris@dk.com', 'yes'),
('hugepernton', 'hugepentona@mail.ru', 'yes');

INSERT INTO `sellers` (`is_user`)
SELECT id FROM users
WHERE is_seller='yes';

UPDATE `sellers` SET `shop_name` = 'My wonderful shop', `contact_address` = 'Moscow, 111674' WHERE (`id` = '1') and (`is_user` = '3');
UPDATE `sellers` SET `shop_name` = 'Jeans for everyone', `contact_address` = 'St Petersburg, ul. Koroleva 12a' WHERE (`id` = '2') and (`is_user` = '4');
UPDATE `sellers` SET `shop_name` = 'Crystals', `contact_address` = 'Moscow' WHERE (`id` = '3') and (`is_user` = '7');
UPDATE `sellers` SET `shop_name` = 'Furniture Wonder', `contact_address` = 'Perm' WHERE (`id` = '4') and (`is_user` = '9');
UPDATE `sellers` SET `shop_name` = 'Lightning', `contact_address` = 'Samara, 443124' WHERE (`id` = '5') and (`is_user` = '13');
UPDATE `sellers` SET `shop_name` = 'Lamps Magic', `contact_address` = 'Omsk' WHERE (`id` = '6') and (`is_user` = '14');
UPDATE `sellers` SET `shop_name` = 'Black Beaver', `contact_address` = 'Taganrog, ul. Kantemirskogo' WHERE (`id` = '7') and (`is_user` = '16');
UPDATE `sellers` SET `shop_name` = 'Connita Powers', `contact_address` = 'Smolenk' WHERE (`id` = '8') and (`is_user` = '17');
UPDATE `sellers` SET `shop_name` = 'At Clare', `contact_address` = 'Moscow' WHERE (`id` = '10') and (`is_user` = '25');
UPDATE `sellers` SET `shop_name` = 'Anisimova Shop', `contact_address` = 'Omsk, Kuvalova Street' WHERE (`id` = '9') and (`is_user` = '18');
UPDATE `sellers` SET `shop_name` = 'Handmade Best', `contact_address` = 'Moscow, ul. Solnechnaya' WHERE (`id` = '11') and (`is_user` = '26');
UPDATE `sellers` SET `shop_name` = 'Pendants one Love', `contact_address` = 'Kiev' WHERE (`id` = '12') and (`is_user` = '27');
UPDATE `sellers` SET `shop_name` = 'Heart Gifts', `contact_address` = 'Paris, Chatee' WHERE (`id` = '13') and (`is_user` = '28');
UPDATE `sellers` SET `shop_name` = 'Clothes for kids', `contact_address` = 'Kopenhagen' WHERE (`id` = '14') and (`is_user` = '29');
UPDATE `sellers` SET `shop_name` = 'Wool and Co', `contact_address` = 'Sochi' WHERE (`id` = '15') and (`is_user` = '30');
UPDATE `sellers` SET `shop_name` = 'Soeren and Partners', `contact_address` = 'Uralsk' WHERE (`id` = '16') and (`is_user` = '31');
UPDATE `sellers` SET `shop_name` = 'Sons and Daughters', `contact_address` = 'Sochi, Krasnogo Oktyabra Street' WHERE (`id` = '17') and (`is_user` = '32');
UPDATE `sellers` SET `shop_name` = 'Gulnara', `contact_address` = 'Karavaev' WHERE (`id` = '18') and (`is_user` = '33');
UPDATE `sellers` SET `shop_name` = 'Amelia', `contact_address` = 'Ekaterinburg, Lenina Street' WHERE (`id` = '19') and (`is_user` = '34');
UPDATE `sellers` SET `shop_name` = 'Flowers', `contact_address` = 'Moscow' WHERE (`id` = '20') and (`is_user` = '35');
UPDATE `sellers` SET `shop_name` = 'Magic Bean', `contact_address` = 'Odintsovo' WHERE (`id` = '21') and (`is_user` = '36');
UPDATE `sellers` SET `shop_name` = 'Energy Crystal', `contact_address` = 'Lyubertsy, 111674' WHERE (`id` = '23') and (`is_user` = '38');
UPDATE `sellers` SET `shop_name` = 'Bottle UP', `contact_address` = 'Krasnoznamensk' WHERE (`id` = '22') and (`is_user` = '37');
UPDATE `sellers` SET `shop_name` = 'Happy kids', `contact_address` = 'Krivoy Rog' WHERE (`id` = '24') and (`is_user` = '39');
UPDATE `sellers` SET `shop_name` = 'Handmade chick', `contact_address` = 'Vladimir' WHERE (`id` = '25') and (`is_user` = '40');
UPDATE `sellers` SET `shop_name` = 'Blonde Bomb', `contact_address` = 'Kiev' WHERE (`id` = '26') and (`is_user` = '41');
UPDATE `sellers` SET `shop_name` = 'Pink shoes', `contact_address` = 'Minks' WHERE (`id` = '27') and (`is_user` = '42');
UPDATE `sellers` SET `shop_name` = 'Alice in Wonderland', `contact_address` = 'Kishinev' WHERE (`id` = '28') and (`is_user` = '43');
UPDATE `sellers` SET `shop_name` = 'Best Shop Ever', `contact_address` = 'Moscow, Pokrovskaya Street 4' WHERE (`id` = '29') and (`is_user` = '44');
UPDATE `sellers` SET `shop_name` = 'The Bestest Shop Ever', `contact_address` = 'Moscow, Pokrovskaya Street 5' WHERE (`id` = '30') and (`is_user` = '45');



INSERT INTO `products_categories` (`category_name`) VALUES ('jeans and trousers'),
('underwear'),
('shirts'),
('skirts'),
('accessories'),
('jewelry'),
('dresses'),
('decor'),
('shoes');

INSERT INTO `products` (`seller_id`, `product_name`, `price`, `category`, `customisation`, `shipped`) VALUES 
('1', 'High heels with golden heel decor', '3200', '9', 'yes', 'yes'),
('1', 'Red heels Instina', '2100', '9', 'no', 'yes'),
('2', 'jeans with polka pattern, female', '2100', '1', 'yes', 'yes'),
('3', 'Princess power crystal', '450', '6', 'no', 'yes'),
('3', 'Princess magic crystal', '500', '6', 'yes', 'yes'),
('4', 'Mapple cabinet, small', '5400', '8', 'no', 'yes'),
('4', 'Oak table with carved legs "Celtic" ', '15990', '8', 'yes', 'no'),
('4', 'Oak chair "Celtic"', '9090', '8', 'no', 'no'),
('4', 'Rocking Horse, birch', '4000', '8', 'no', 'no'),
('4', 'Carved wooden chair', '6900', '8', 'yes', 'yes'),
('5', 'Panties with your image', '999', '2', 'yes', 'yes'),
('6', 'Nightlamp with golden drops', '3400', '8', 'yes', 'no'),
('6', 'Nightlamp Clouds', '1300', '8', 'no', 'yes'),
('7', 'Real man jeans', '2000', '1', 'no', 'yes'),
('8', 'Umbrella with carved handle', '3799', '5', 'no', 'yes'),
('9', 'Little Black Bag', '3900', '5', 'yes', 'yes'),
('10', 'Male shirt, office', '2300', '3', 'no', 'yes'),
('10', 'Male polo shirt', '2900', '3', 'yes', 'yes'),
('11', 'Office striped dress', '5000', '7', 'no', 'yes'),
('11', 'Dress, casual formal', '6900', '7', 'no', 'yes'),
('11', 'Gown with silver lining', '6999', '7', 'yes', 'yes'),
('11', 'Gown purple', '5099', '7', 'yes', 'yes'),
('12', 'Pendant with shark teeth', '2399', '6', 'no', 'yes'),
('14', 'School skirt', '700', '4', 'yes', 'yes'),
('14', 'Striped skirt', '600', '4', 'yes', 'yes'),
('23', 'Crystal bowl, devination', '1300', '8', 'yes', 'yes'),
('13', 'Heart-shaped earrings', '400', '6', 'no', 'yes'),
('14', 'jeans for kids', '500', '1', 'yes', 'yes'),
('15', 'Woolen sweater', '1400', '3', 'yes', 'yes'),
('16', 'Salt tower, standing decor', '799', '8', 'no', 'yes'),
('17', 'Sandals with straps', '999', '9', 'no', 'yes'),
('18', 'Male underwear', '400', '2', 'yes', 'yes'),
('19', 'Lingerie, lace red', '1399', '2', 'no', 'yes'),
('27', 'Red shoes with golden buckles', '2300', '9', 'yes', 'yes'),
('20', 'Red dress with flowers', '2600', '7', 'no', 'yes'),
('20', 'Emerald summer dress FLOWER QUEEN', '4000', '7', 'no', 'yes'),
('30', 'Glittering ceiling stick-on decor', '650', '8', 'yes', 'yes'),
('21', 'Glowing postman bag strap with crystals', '2999', '5', 'no', 'yes'),
('22', 'Flowery skirt Aliana', '2100', '4', 'no', 'yes'),
('22', 'Skirt polka dots', '1200', '4', 'no', 'yes'),
('23', 'Moonstone', '4000', '8', 'no', 'yes'),
('29', 'Epoxy resin pendant with your photo', '500', '6', 'no', 'yes'),
('19', 'Pendant Flower Gallery', '400', '6', 'no', 'yes'),
('24', 'Moonstone pendant', '600', '6', 'yes', 'yes'),
('25', 'Heart-shaped earrings with swarovski crystals', '2590', '6', 'no', 'yes'),
('25', 'jeans female', '1300', '6', 'no', 'yes'),
('27', 'Buckle shoes', '1000', '9', 'no', 'yes'),
('25', 'Summer dress Dreams', '1340', '7', 'no', 'yes'),
('26', 'Pink summer dress with flower patterns', '2000', '7', 'yes', 'yes'),
('28', 'White Rabbit clock, small', '1200', '8', 'no', 'yes'),
('28', 'White Rabbit clock', '2400', '8', 'no', 'yes'),
('29', 'Pendant Hearts of Gold', '2500', '6', 'no', 'yes'),
('29', 'Epoxy resin pendant', '500', '6', 'no', 'yes'),
('29', 'Epoxy resin ring', '600', '6', 'no', 'yes'),
('29', 'Umbrella with cat ears', '1200', '5', 'no', 'yes'),
('29', 'Umbrella with dog ears', '1250', '5', 'no', 'yes'),
('29', 'Bag with kitten patterned side', '1300', '5', 'no', 'no'),
('30', 'Beach bag GLAMOUR', '2000', '5', 'no', 'yes');

INSERT INTO contests (`starts`, `finishes`, `prize`) VALUES ('2019-09-01 00:00:00', '2019-12-01 00:00:00', '4'),
('2019-11-20 12:00:00', '2020-01-01 00:00:00', '58'), -- приз конкурса - это товар с id 43
('2019-10-04 23:59:59', '2019-10-14 00:00:00', '49'),
('2019-05-01 23:59:59', '2019-09-01 00:00:00', '2'), -- конкурс завершился и победил пользователь с id =32
('2019-09-21 12:00:00', '2019-09-21 12:00:00', '33');

UPDATE contests SET `winner` = '32' WHERE (`id` = '4');
UPDATE contests SET `winner` = '12' WHERE (`id` = '5');

INSERT INTO academy (`activity_type`, `date`, `count`) VALUES ('vebinar', '2019-12-14 12:00:00', '5'),
('article', '2019-10-23 19:10:31', '300'),
('article', '2019-11-13 12:10:31', '430'),
('article', '2019-12-03 19:04:32', '342'),
('article', '2019-11-23 13:09:00', '123'),
('workshop', '2019-11-11 19:00:00', '30'),
('workshop', '2019-10-21 12:15:00', '40'),
('workshop', '2019-12-04 10:00:00', '3');

INSERT INTO `users_profiles` (`user_id`, `username`)
SELECT id, username FROM users;

UPDATE users_profiles SET real_name = 'Peter Pavlov', gender = 'male', birthday = '1971-10-18', photo_id = '1', hometown = 'Kemerov', shipping_address = 'Kemerov, ul Koroleva 12, kv. 78, 334987', telephone_number ='+79171689537', interests = 'sewing, baking'  WHERE (`user_id` = '1');
UPDATE users_profiles SET real_name = 'Foidora Benks', gender = 'female', birthday = '1951-11-04', photo_id = '2', hometown = 'Moscow', shipping_address = 'Moscow, ul Krasnoy Armee 13, kv. 98, 111154', telephone_number ='+79141694037', interests = 'crafts, baking' WHERE (`user_id` = '2');
UPDATE users_profiles SET real_name = 'Elena Helnova', gender = 'female', photo_id = '3', hometown = 'Kiev', shipping_address = 'Kiev, ul Vatuz 4, kv. 4, 334987', telephone_number ='+301178485007'  WHERE (`user_id` = '3');
UPDATE users_profiles SET real_name = 'Soeren Marksohn', gender = 'male', birthday = '1961-06-03', hometown = 'Copenhagen', shipping_address = 'Moscow, Tverskaya Street 11, 111098', telephone_number ='+409753325531' WHERE (`user_id` = '4');
UPDATE users_profiles SET real_name = 'Helga Dutch', gender = 'female', birthday = '1984-01-31', photo_id = '4', telephone_number ='+79371909500', interests = 'painting' WHERE (`user_id` = '5');
UPDATE users_profiles SET real_name = 'Rovanis Peters', gender = 'male', birthday = '1964-02-28', photo_id = '5', hometown = 'Moscow', telephone_number ='+79001009531', interests = 'epoxy resin and wood carving' WHERE (`user_id` = '6');
UPDATE users_profiles SET real_name = 'Iohim Gaus', gender = 'male' WHERE (`user_id` = '7');
UPDATE users_profiles SET real_name = 'Josi Peters' WHERE (`user_id` = '9');
UPDATE users_profiles SET gender = 'female' WHERE (`user_id` = '10');
UPDATE users_profiles SET real_name = 'Faseroava Irina', birthday = '1971-10-18', photo_id = '6', hometown = 'Omsk', shipping_address = 'Omsk, ul. Petrenkova 12, kv. 93, 420885', telephone_number ='+79291684402', interests = 'shoes, IT, spicy foods' WHERE (`user_id` = '11');
UPDATE users_profiles SET real_name = 'Arina Kravtschenko', gender = 'female' WHERE (`user_id` = '12');
UPDATE users_profiles SET real_name = 'Sufur Tor', gender = 'male' WHERE (`user_id` = '13');
UPDATE users_profiles SET real_name = 'Galina Uslova', gender = 'female', shipping_address = 'Ekaterinburg, ul. Kadyasheva 93, kv. 24, 334987', telephone_number ='+70974689531' WHERE (`user_id` = '14');
UPDATE users_profiles SET gender = 'female' WHERE (`user_id` = '15');
UPDATE users_profiles SET real_name = 'Alina' WHERE (`user_id` = '16');
UPDATE users_profiles SET real_name = 'Albina Khromova', gender = 'female' WHERE (`user_id` = '17');
UPDATE users_profiles SET real_name = 'Marina Kuznetsova', gender = 'female', birthday = '1991-04-29', photo_id = '7', interests = 'felting' WHERE (`user_id` = '18');
UPDATE users_profiles SET real_name = 'Maxim Karterov', gender = 'male' WHERE (`user_id` = '19');
UPDATE users_profiles SET real_name = 'Andrey Tokarev', gender = 'male' WHERE (`user_id` = '20');
UPDATE users_profiles SET real_name = 'Kirill Omarov', gender = 'male' WHERE (`user_id` = '21');
UPDATE users_profiles SET real_name = 'Elena Martyionava', gender = 'female', birthday = '1993-06-24', hometown = 'St. Petersburg', shipping_address = 'St. Petersburg, Dvortsovaya Ploshad" 53, kv. 32, 798371', interests = 'felting, sewing, origami' WHERE (`user_id` = '22');
UPDATE users_profiles SET real_name = 'Antonina Michel', gender = 'female', photo_id = '8', interests = 'baking' WHERE (`user_id` = '23');
UPDATE users_profiles SET real_name = 'Sanders' WHERE (`user_id` = '25');
UPDATE users_profiles SET real_name = 'Tamara Ivanova', gender = 'female', birthday = '1983-12-09', photo_id = '9', hometown = 'Taganrog', shipping_address = 'Vladimir, ul Knyazya 32, kv. 289, 298467', telephone_number ='+77171049930', interests = 'origami, felting' WHERE (`user_id` = '26');
UPDATE users_profiles SET real_name = 'Ivan Sergeev', gender = 'male' WHERE (`user_id` = '28');
UPDATE users_profiles SET real_name = 'Irina Karpenko', gender = 'female', birthday = '1986-04-17', photo_id = '10', hometown = 'Uralsk', shipping_address = 'Moscow, ul Solnechnaya 3, kv. 389, 178193', telephone_number ='+79641680823' WHERE (`user_id` = '29');
UPDATE users_profiles SET real_name = 'Olga Helsdoz', gender = 'female' WHERE (`user_id` = '30');
UPDATE users_profiles SET real_name = 'Peter', gender = 'male', birthday = '1959-07-24', photo_id = '11', shipping_address = 'Kalimov, ul. Moscovskaya 87, kv. 78, 987467', telephone_number ='+79078287737', interests = 'painting, origami, epoxy resin' WHERE (`user_id` = '31');
UPDATE users_profiles SET real_name = 'Peter', gender = 'male' WHERE (`user_id` = '32');
UPDATE users_profiles SET real_name = 'Amina Karpova', gender = 'female', birthday = '1957-06-30', photo_id = '12', telephone_number ='+79034689595', interests = 'baking, felting, painting' WHERE (`user_id` = '33');
UPDATE users_profiles SET real_name = 'Olimpiada Serova', gender = 'female', shipping_address = 'Moskva, ul. Sochinskaya 34, kv. 271, 116794', telephone_number ='+79251949787' WHERE (`user_id` = '34');
UPDATE users_profiles SET real_name = 'Sergey Krasnov', gender = 'male' WHERE (`user_id` = '35');
UPDATE users_profiles SET birthday = '1990-11-30', hometown = 'Smolensk', shipping_address = 'Smolensk, Leningradskaya Street 58, kv. 34', telephone_number ='+79773887509', interests = 'jogging, sports, sportswear' WHERE (`user_id` = '36');
UPDATE users_profiles SET real_name = 'Maria Blanc', gender = 'female' WHERE (`user_id` = '37');
UPDATE users_profiles SET real_name = 'Marina Rustova', gender = 'female', birthday = '1980-03-03', photo_id = '13', telephone_number ='+79041643538', interests = 'making shoes' WHERE (`user_id` = '38');
UPDATE users_profiles SET real_name = 'Uliana', gender = 'female' WHERE (`user_id` = '39');
UPDATE users_profiles SET real_name = 'Helen Hoffman', gender = 'female', photo_id = '14', hometown = 'Munich', shipping_address = 'Salsk, Pobedya Street 412, app. 73, 764902', telephone_number ='+46802169537', interests = 'horse riding, cooking' WHERE (`user_id` = '41');
UPDATE users_profiles SET real_name = 'Karina Usifova', gender = 'female', interests = 'baking, cooking and sewing'  WHERE (`user_id` = '42');
UPDATE users_profiles SET birthday = '1998-12-04', photo_id = '15', hometown = 'Krasnodar', shipping_address = 'Krasnodar, Sochinskaya Street 84, kv. 4, 334987', telephone_number ='+79190688332', interests = 'beach, sun, pretty things' WHERE (`user_id` = '43');
UPDATE users_profiles SET real_name = 'Jamilya Tsarinova', gender = 'female', birthday = '1934-09-07', photo_id = '16', hometown = 'Adler', shipping_address = 'Krivoy Rog, Tsentarnaya 8', interests = 'knitting, crochye' WHERE (`user_id` = '44');
UPDATE users_profiles SET real_name = 'Madam Smirnoff', gender = 'female' WHERE (`user_id` = '45');


INSERT INTO `users_subscribed_tos` (`user_id`, `seller_id`) VALUES 
('1', '2'),
('1', '4'),
('1', '3'),
('2', '12'),
('3', '12'),
('3', '4'),
('5', '12'),
('18', '30'),
('34', '30'),
('34', '26'),
('34', '28'),
('40', '29'),
('11', '13'),
('14', '2'),
('12', '5'),
('17', '6'),
('18', '6'),
('19', '8'),
('21', '11'),
('24', '19'),
('37', '20'),
('39', '21'),
('5', '23'),
('6', '24'),
('7', '17');

INSERT INTO `seasonal_promotions` (`season`, `starts`, `ends`, `is_promoted`) VALUES 
('winter', '2020-01-01 00:00:00', '2020-03-01 00:00:00', '1'),
('spring', '2020-03-01 23:59:59', '2020-05-23 23:59:59', '5'),
('summer', '2020-05-30 00:00:00', '2020-09-01 00:00:00', '6'),
('autumn', '2019-09-01 23:59:59', '2019-09-20 23:59:59', '9'),
('autumn', '2019-09-20 00:00:00', '2019-11-01 23:59:59', '2'),
('autumn', '2019-09-30 00:59:59', '2019-12-01 00:59:59', '3'),
('winter', '2020-02-01 02:00:00', '2020-03-13 02:00:00', '4');


