/* База данных сайта livemaster, где можно продавать и покупать изделия ручной работы. Можно регистрироваться как пользователь, подписываться на разные магазины, рассылки по интересам, также есть Академия (проводят вебинары и публикуют статьи). После регистрации как пользователь, можно создать магазин, т. е. все продавцы одновременно и пользователи, но не все пользователи = продавцы.
 БД решает задачи :
 a) хранения всей необходимой информации о: 
	1) пользователях (инфо, адрес доставки, интересы), продавцах
	2) товарах
	3) мероприятиях
	4) заказах
b) обеспечивает получение данных по соответствующим запросам.
с) недопускает дублирование ряда данных, для которых уникальность критична
d) обеспечевает целостность  данных
*/

DROP DATABASE IF EXISTS db_livemaster;
CREATE DATABASE db_livemaster DEFAULT CHARACTER SET utf8 COLLATE utf8_bin ;
USE db_livemaster;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id SERIAL,
  username VARCHAR(45) NOT NULL UNIQUE,
  email VARCHAR(120) NOT NULL UNIQUE,
  is_seller ENUM ('no', 'yes') NOT NULL, -- является ли пользователь продавцом
  PRIMARY KEY (id));
  
DROP TABLE IF EXISTS sellers;
CREATE TABLE sellers (
  id SERIAL,
  shop_name VARCHAR(45),
  contact_address VARCHAR(255) NULL,
  is_user BIGINT UNSIGNED NOT NULL,
  FOREIGN KEY (is_user) REFERENCES users(id)
  ON UPDATE CASCADE
  , -- чтобы быть продавцом, нужно быть пользователем. Но можно удалить магазин и остаться пользователем
  PRIMARY KEY (id, is_user)); -- у одного пользователя может быть 2 продавца-магазина. У юзера свой id, у продавца ставится свой id. Поэтому ключом идет пара
  
DROP TABLE IF EXISTS users_profiles;
CREATE TABLE users_profiles (
	user_id SERIAL,
    real_name VARCHAR(100), -- Указывать своё настоящее имя на сайте необязательно, поэтому будет храниться вместе имя+фамилия, все равно поиск/сортировка по этому параметру недоступны на сайте (продавцов ищут по названию магазина) 
    gender ENUM('male', 'female') NULL,
    birthday DATE NULL,
	photo_id BIGINT UNSIGNED NULL,
    created_at DATETIME DEFAULT NOW(),
    hometown VARCHAR(100) NULL,
    shipping_address VARCHAR(255), -- Юзер может ввести один раз, или вводить при каждом заказе 
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
CREATE TABLE users_subscribed_tos(  -- Можно подписаться на мастера (магазин то есть), когда он разместит новую работу, пользователь получит сообщение
	user_id BIGINT UNSIGNED NOT NULL,
	seller_id BIGINT UNSIGNED NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (seller_id) REFERENCES sellers(id),
    PRIMARY KEY (user_id, seller_id)); -- чтобы не было 2 записей о пользователе и мастере 
  
DROP TABLE IF EXISTS `messages`;
CREATE TABLE `messages` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `from_user_id` BIGINT UNSIGNED NOT NULL,
  `to_user_id` BIGINT UNSIGNED NOT NULL,
  `body` TEXT COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP(),
  FOREIGN KEY (from_user_id) REFERENCES users(id),
  FOREIGN KEY (to_user_id) REFERENCES users(id),
  PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS products_categories;
CREATE TABLE products_categories (
 category_id SERIAL,
 category_name VARCHAR(45),
PRIMARY KEY (category_id));

DROP TABLE IF EXISTS photos;
CREATE TABLE photos ( 
id SERIAL,
photo_name VARCHAR(255) NULL, -- например best_pic.jpg
photo_of ENUM ('user', 'product'), -- все картинки в одной таблице, так как продавец может поставить себе на аватарку его самый запоминающийся товар, тем самым привлекая покупателей, когда продавец, например, пишет на форуме
PRIMARY KEY (id));

DROP TABLE IF EXISTS products;
CREATE TABLE products ( -- каталог общий для всех, под товаром подписывают магазин продавца
  id SERIAL,
  seller_id BIGINT UNSIGNED NOT NULL,
  product_name VARCHAR(45) NOT NULL,
  product_photo BIGINT UNSIGNED NULL,
  price DECIMAL(13,2) NOT NULL,
  category BIGINT UNSIGNED NOT NULL,
  customisation ENUM('no', 'yes') NOT NULL, -- некоторые изделия мастера могут по запросу перекрасить/изготовить такое же, но бордовое и т.п.
  shipped ENUM('no', 'yes') NOT NULL, -- очень хрупкие вещи не отправляют почтой
  FOREIGN KEY (seller_id) REFERENCES sellers(id)
  ON UPDATE CASCADE
  ,
  FOREIGN KEY (product_photo) REFERENCES photos(id)
  ON UPDATE CASCADE -- можно удалить товар, а картинка его все равно останется. например, как образец работы (хотя ее уже продали, мастер может сделать похожую)
  ,
  FOREIGN KEY (category) REFERENCES products_categories(category_id)
  ,
  PRIMARY KEY (id));
  

DROP TABLE IF EXISTS seasonal_promotions;
CREATE TABLE seasonal_promotions (
  id SERIAL,
  season ENUM('winter', 'spring', 'summer', 'autumn') NOT NULL,
  starts DATETIME NOT NULL,
  ends DATETIME NOT NULL,
  is_promoted BIGINT UNSIGNED NOT NULL, -- продвигаемая категория, например зимой - шарфы. Товары по одному не продвигаются на сайте
  FOREIGN KEY (is_promoted) REFERENCES products_categories(category_id) 
    	ON UPDATE CASCADE 
        ,
  PRIMARY KEY (id));

DROP DATABASE IF EXISTS `orders`;
CREATE TABLE `orders` (
id SERIAL,
ordered_products JSON NOT NULL,
ship_to BIGINT UNSIGNED,
shipped_by BIGINT UNSIGNED NOT NULL,
payment_method ENUM('credit_card', 'paypal', 'cash') NOT NULL,
paid ENUM('no', 'yes') NOT NULL,
ship_to_address VARCHAR(255) NULL, -- если самовывоз, то адрес не указывается, поэтому может быть NULL
FOREIGN KEY (ship_to) REFERENCES users(id)
	ON DELETE RESTRICT
	, -- если юзер удалится, его история заказов все равно сохранится
FOREIGN KEY (shipped_by) REFERENCES sellers(id)
	ON DELETE RESTRICT
	, -- магазин тоже можно удалить, история заказов остается
  PRIMARY KEY (`id`));
  
  DROP DATABASE IF EXISTS `contests`;
 CREATE TABLE `contests` (
  `id` SERIAL,
  `starts` DATETIME NOT NULL,
  `finishes` DATETIME NOT NULL,
  `winner` BIGINT UNSIGNED, -- id пользователя
  `prize` BIGINT UNSIGNED, -- какой-то товар с сайта, поле хранит id этого товара
  FOREIGN KEY (winner) REFERENCES users(id) 
    	ON DELETE restrict
	,
	FOREIGN KEY (prize) REFERENCES products(id) 
    	ON DELETE restrict
	,
  PRIMARY KEY (`id`));
  
  DROP DATABASE IF EXISTS `academy`; -- Академия - так называется раздел сайта, на котором публикуют информацию о вебинарах, воркшопах. Здесь же мастера могут публиковать статьи
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
('hugepernton', 'hugepentona@mail.ru', 'yes'),
('gdsongds', 'gdsongds@mail.ru', 'no'),
('cutara', 'tamataa@gmail.com', 'no'),
('soerenv', 'soerenv@mt.dk', 'no'),
('hellora', 'helloitsme@gmail.com', 'no'),
('telemorta', 'telenoragaov@gmail.com', 'no'),
('martahapavolva', 'pavlova@mail.ru', 'no'),
('ginoraa', 'egv.kisileva@mail.ru', 'no'),
('fadsje', 'wegsdghas@mail.ru', 'no'),
('wetedgfds', 'pomweg@gmail.com', 'no'),
('polina98', 'polina98a@mail.ru', 'no'),
('fsgsd', 'ewfdsg@mgmail.com', 'no'),
('sgdsd', 'gsdgs@gmail.com', 'no'),
('tamwgsata', 'teyhegs@gmail.com', 'no'),
('sdgsdt', 'hgdftefs@hotmail.ru', 'no'),
('w54hdfg', '324tewfd@hotmail.ru', 'no'),
('42523fsdg', 'sgsdfh34@gmail.com', 'no'),
('hfdsgwe', 'hdfhs3@mail.ru', 'no'),
('gfs3t223', 'fsgs23t@mail.ru', 'no');

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

INSERT INTO photos (photo_name, photo_of) VALUES ('aa.jpg', 'user'),
('my.jpg', 'product'),
('jeans.jpg', 'product'),
('sdgfgs.jpg', 'product'),
('33.png', 'product'),
('222a.jpg', 'user'),
('gd.jpg', 'product'),
('photo.png', 'user'),
('photo3.jpg', 'product'),
('photo44.png', 'user'),
('default.jpg', 'product'),
('noname.png', 'product'),
('user.jpg', 'user'),
('mine.jpg', 'product'),
('cool.png', 'product'),
('somephoto.jpg', 'user'),
('dsfds.jpg', 'user'),
('eeee.jpg', 'product'),
('somephoto3.png', 'product'),
('somephoto5.jpg', 'product'),
('eeeeee.png', 'user'),
('rrr.png', 'product'),
('prodcut.png', 'product'),
('products.jpg', 'user'),
('ae.jpg', 'product'),
('at.png', 'product'),
('tel.jpg', 'user'),
('gf.gif', 'user'),
('mypic.gif', 'product'),
('pic.jpg', 'product'),
('unnamed.jpg', 'product'),
('ee.jpg', 'product'),
('rr.png', 'product'),
('tt.jpg', 'user'),
('yy.jpg', 'user'),
('yui.jpg', 'product'),
('trydf.png', 'product'),
('gdfgs.jpg', 'product'),
('dfsgdf.png', 'user'),
('gfdgf.png', 'product'),
('ert.png', 'product'),
('bgfd.jpg', 'user'),
('345345.jpg', 'product'),
('disc.png', 'product'),
('ggsfds.jpg', 'user'),
('4354.gif', 'user'),
('34534.gif', 'product'),
('534534.jpg', 'product'),
('5343.jpg', 'product'),
('treter.jpg', 'product'),
('4534.png', 'product'),
('erwtrew453.jpg', 'user'),
('dgfeg54wtgsfds.jpg', 'user'),
('gfgser43.jpg', 'product'),
('hgws.png', 'product'),
('gerwsg.jpg', 'product'),
('resg.png', 'user'),
('wert.png', 'product'),
('gggg.png', 'product'),
('products3534.jpg', 'user'),
('trew.jpg', 'product'),
('35tw43.png', 'product'),
('gfs45.jpg', 'user'),
('ghsq.gif', 'user'),
('adsa.gif', 'product'),
('piweqrwc.jpg', 'product'),
('rewq.jpg', 'product'),
('45r3wafr.jpg', 'user');

INSERT INTO `products` (`seller_id`, `product_name`, `price`, `category`, `customisation`, `shipped`, `product_photo`) VALUES 
('1', 'High heels with golden heel decor', '3200', '9', 'yes', 'yes', 1),
('1', 'Red heels Instina', '2100', '9', 'no', 'yes', 2),
('2', 'jeans with polka pattern, female', '2100', '1', 'yes', 'yes', NULL),
('3', 'Princess power crystal', '450', '6', 'no', 'yes', NULL),
('3', 'Princess magic crystal', '500', '6', 'yes', 'yes', 3),
('4', 'Mapple cabinet, small', '5400', '8', 'no', 'yes', NULL),
('4', 'Oak table with carved legs "Celtic" ', '15990', '8', 'yes', 'no', 4),
('4', 'Oak chair "Celtic"', '9090', '8', 'no', 'no', NULL),
('4', 'Rocking Horse, birch', '4000', '8', 'no', 'no', NULL),
('4', 'Carved wooden chair', '6900', '8', 'yes', 'yes', 5),
('5', 'Panties with your image', '999', '2', 'yes', 'yes', 6),
('6', 'Nightlamp with golden drops', '3400', '8', 'yes', 'no', 7),
('6', 'Nightlamp Clouds', '1300', '8', 'no', 'yes', 8),
('7', 'Real man jeans', '2000', '1', 'no', 'yes', 9),
('8', 'Umbrella with carved handle', '3799', '5', 'no', 'yes', 10),
('9', 'Little Black Bag', '3900', '5', 'yes', 'yes', 11),
('10', 'Male shirt, office', '2300', '3', 'no', 'yes', 12),
('10', 'Male polo shirt', '2900', '3', 'yes', 'yes', 13),
('11', 'Office striped dress', '5000', '7', 'no', 'yes', 14),
('11', 'Dress, casual formal', '6900', '7', 'no', 'yes', 15),
('11', 'Gown with silver lining', '6999', '7', 'yes', 'yes', 16),
('11', 'Gown purple', '5099', '7', 'yes', 'yes', 17),
('12', 'Pendant with shark teeth', '2399', '6', 'no', 'yes', 18),
('14', 'School skirt', '700', '4', 'yes', 'yes', 19),
('14', 'Striped skirt', '600', '4', 'yes', 'yes', 20),
('23', 'Crystal bowl, devination', '1300', '8', 'yes', 'yes', 22),
('13', 'Heart-shaped earrings', '400', '6', 'no', 'yes', 21),
('14', 'jeans for kids', '500', '1', 'yes', 'yes', 23),
('15', 'Woolen sweater', '1400', '3', 'yes', 'yes', NULL),
('16', 'Salt tower, standing decor', '799', '8', 'no', 'yes', 24),
('17', 'Sandals with straps', '999', '9', 'no', 'yes', 25),
('18', 'Male underwear', '400', '2', 'yes', 'yes', 26),
('19', 'Lingerie, lace red', '1399', '2', 'no', 'yes', 27),
('27', 'Red shoes with golden buckles', '2300', '9', 'yes', 'yes', 28),
('20', 'Red dress with flowers', '2600', '7', 'no', 'yes', 29),
('20', 'Emerald summer dress FLOWER QUEEN', '4000', '7', 'no', 'yes', 30),
('30', 'Glittering ceiling stick-on decor', '650', '8', 'yes', 'yes', 31),
('21', 'Glowing postman bag strap with crystals', '2999', '5', 'no', 'yes', 32),
('22', 'Flowery skirt Aliana', '2100', '4', 'no', 'yes', 33),
('22', 'Skirt polka dots', '1200', '4', 'no', 'yes', 34),
('23', 'Moonstone', '4000', '8', 'no', 'yes', 35),
('29', 'Epoxy resin pendant with your photo', '500', '6', 'no', 'yes', 36),
('19', 'Pendant Flower Gallery', '400', '6', 'no', 'yes', 37),
('24', 'Moonstone pendant', '600', '6', 'yes', 'yes', 38),
('25', 'Heart-shaped earrings with swarovski crystals', '2590', '6', 'no', 'yes', 39),
('25', 'jeans female', '1300', '6', 'no', 'yes', 40),
('27', 'Buckle shoes', '1000', '9', 'no', 'yes', 41),
('25', 'Summer dress Dreams', '1340', '7', 'no', 'yes', 42),
('26', 'Pink summer dress with flower patterns', '2000', '7', 'yes', 'yes', 43),
('28', 'White Rabbit clock, small', '1200', '8', 'no', 'yes', 44),
('28', 'White Rabbit clock', '2400', '8', 'no', 'yes', 45),
('29', 'Pendant Hearts of Gold', '2500', '6', 'no', 'yes', 46),
('29', 'Epoxy resin pendant', '500', '6', 'no', 'yes', 47),
('29', 'Epoxy resin ring', '600', '6', 'no', 'yes', 48),
('29', 'Umbrella with cat ears', '1200', '5', 'no', 'yes', 49),
('29', 'Umbrella with dog ears', '1250', '5', 'no', 'yes', 50),
('29', 'Bag with kitten patterned side', '1300', '5', 'no', 'no', 51),
('30', 'bag PINK SIZE', '2500', '5', 'no', 'yes', 52),
('29', 'Kitten sides', '2000', '5', 'no', 'no', 53),
('30', 'Beach bag SUN', '2100', '5', 'no', 'yes', 54),
('29', 'Bag Golden Ret', '1090', '5', 'no', 'no', 55),
('30', 'Bag Kiss', '2000', '5', 'no', 'yes', NULL);

INSERT INTO contests (`starts`, `finishes`, `prize`) VALUES ('2019-09-01 00:00:00', '2019-12-01 00:00:00', '4'),
('2019-11-20 12:00:00', '2020-01-01 00:00:00', '58'), -- приз конкурса - это товар с id 43
('2019-10-04 23:59:59', '2019-10-14 00:00:00', '49'),
('2019-05-01 23:59:59', '2019-09-01 00:00:00', '2'), -- конкурс завершился и победил пользователь с id =32
('2019-09-21 12:00:00', '2019-09-21 12:00:00', '33');

UPDATE contests SET `winner` = '32' WHERE (`id` = '4');
UPDATE contests SET `winner` = '12' WHERE (`id` = '5');

INSERT INTO academy (`activity_type`, `date`, `count`, `author`) VALUES 
('vebinar', '2019-12-14 12:00:00', '5', '2'),
('article', '2019-10-23 19:10:31', '300', '1'),
('article', '2019-11-13 12:10:31', '430', '2'),
('article', '2019-12-03 19:04:32', '342', '3'),
('article', '2019-11-23 13:09:00', '123', '6'),
('workshop', '2019-11-11 19:00:00', '30', '9'),
('workshop', '2019-10-21 12:15:00', '40', '2'),
('workshop', '2019-12-04 10:00:00', '3', '9');

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
UPDATE users_profiles SET real_name = 'Alex Buev', gender = 'male', birthday = '1981-10-18', photo_id = '17' WHERE (`user_id` = '46');
UPDATE users_profiles SET real_name = 'Peter Orlov', gender = 'male', birthday = '1973-11-03', photo_id = '18', hometown = 'Ylianovsk', telephone_number ='+79471649557', interests = 'crafts, sewing'  WHERE (`user_id` = '47');
UPDATE users_profiles SET real_name = 'Max Orlov', gender = 'male', photo_id = '19', hometown = 'Kerch', shipping_address = 'Moscow, ul Wgdfkpova 4, kv. 59, 985467', telephone_number ='+79196689537', interests = 'sewing'  WHERE (`user_id` = '48');
UPDATE users_profiles SET real_name = 'Tamara Snow', gender = 'female', birthday = '1977-10-03', photo_id = '20', telephone_number ='+70471789535', interests = 'jewellry, wood carving'  WHERE (`user_id` = '50');
UPDATE users_profiles SET real_name = 'Alexey Kichaev', gender = 'male', birthday = '1986-06-18', hometown = 'Moscow', shipping_address = 'Peterburg, ul. Sentesfdg 45, kv. 78, 478932', telephone_number ='+70071559547' WHERE (`user_id` = '51');
UPDATE users_profiles SET real_name = 'Maria Subbotina', gender = 'female', photo_id = '21', hometown = 'Gfpdogs', shipping_address = 'Gfpdogs, ul Pogsnd 32, kv. 943, 334987', telephone_number ='+79054675537', interests = 'horses, leaves'  WHERE (`user_id` = '52');
UPDATE users_profiles SET real_name = 'Daria Krasner', gender = 'female', birthday = '1991-09-29', photo_id = '22', telephone_number ='+79171689543' WHERE (`user_id` = '53');
UPDATE users_profiles SET real_name = 'Oxxana Kich', gender = 'female', birthday = '1999-07-05', photo_id = '23', telephone_number ='+79571583535' WHERE (`user_id` = '54');
UPDATE users_profiles SET real_name = 'Orlin', gender = 'female', birthday = '1934-10-18', hometown = 'Kemerov', shipping_address = 'Kemerov, ul Koroleva 43, kv. 543, 334987', telephone_number ='+79171349557', interests = 'crafting'  WHERE (`user_id` = '55');
UPDATE users_profiles SET real_name = 'Amalia Peters', gender = 'female', birthday = '1956-04-24', photo_id = '24', telephone_number ='+79161686536', interests = 'needlework'  WHERE (`user_id` = '56');
UPDATE users_profiles SET real_name = 'Natalia Kisileva', gender = 'female', birthday = '1997-05-20', interests = 'knitting, sewing'  WHERE (`user_id` = '58');
UPDATE users_profiles SET real_name = 'Andrey Savlov', gender = 'male', birthday = '1958-09-21', photo_id = '25', hometown = 'Samara', shipping_address = 'Samara, ul Kirsanova 35, kv. 93, 444987', telephone_number ='+79070089536', interests = 'sewing, needlework, knitting'  WHERE (`user_id` = '59');
UPDATE users_profiles SET real_name = 'Timur Horaph', gender = 'male', birthday = '1989-10-15', shipping_address = 'Moscow, ul. Pobedya 53, kv. 532, 334987' WHERE (`user_id` = '60');

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
('17', '16'),
('18', '6'),
('19', '11'),
('21', '12'),
('24', '22'),
('37', '29'),
('50', '12'),
('55', '15'),
('46', '16'),
('57', '17'),
('60', '29'),
('45', '13'),
('37', '2'),
('12', '12'),
('17', '6'),
('36', '6'),
('37', '8'),
('37', '9'),
('50', '13'),
('51', '2'),
('55', '25'),
('55', '26'),
('55', '6'),
('55', '8');

INSERT INTO `seasonal_promotions` (`season`, `starts`, `ends`, `is_promoted`) VALUES 
('winter', '2020-01-01 00:00:00', '2020-03-01 00:00:00', '1'),
('spring', '2020-03-01 23:59:59', '2020-05-23 23:59:59', '5'),
('summer', '2020-05-30 00:00:00', '2020-09-01 00:00:00', '6'),
('autumn', '2019-09-01 23:59:59', '2019-09-20 23:59:59', '9'),
('autumn', '2019-09-20 00:00:00', '2019-11-01 23:59:59', '2'),
('autumn', '2019-09-30 00:59:59', '2019-12-01 00:59:59', '3'),
('winter', '2020-02-01 02:00:00', '2020-03-13 02:00:00', '4');

INSERT INTO `messages` VALUES 
('1','1','2','Voluptatem ut quaerat quia. Pariatur esse amet ratione qui quia. In necessitatibus reprehenderit et. Nam accusantium aut qui quae nesciunt non.','1995-08-28 22:44:29'), 
('2','2','63','Sint dolores et debitis est ducimus. Aut et quia beatae minus. Ipsa rerum totam modi sunt sed. Voluptas atque eum et odio ea molestias ipsam architecto.','1973-03-18 12:18:28'),
('3','2','34','Sed mollitia quo sequi nisi est tenetur at rerum. Sed quibusdam illo ea facilis nemo sequi. Et tempora repudiandae saepe quo.','1993-09-14 19:45:58'),
('4','2','54','Quod dicta omnis placeat id et officiis et. Beatae enim aut aliquid neque occaecati odit. Facere eum distinctio assumenda omnis est delectus magnam.','1985-11-25 16:56:25'),
('5','5','54','Voluptas omnis enim quia porro debitis facilis eaque ut. Id inventore non corrupti doloremque consequuntur. Molestiae molestiae deleniti exercitationem sunt qui ea accusamus deserunt.','1999-09-19 04:35:46'),
('6','6','6','Rerum labore culpa et laboriosam eum totam. Quidem pariatur sit alias. Atque doloribus ratione eum rem dolor vitae saepe.','1973-11-09 08:12:04'),
('7','54','7','Perspiciatis temporibus doloribus debitis. Et inventore labore eos modi. Quo temporibus corporis minus. Accusamus aspernatur nihil nobis placeat molestiae et commodi eaque.','1998-04-09 00:00:26'),
('8','32','8','Suscipit dolore voluptas et sit vero et sint. Rem ut ratione voluptatum assumenda nesciunt ea. Quas qui qui atque ut. Similique et praesentium non voluptate iure. Eum aperiam officia quia dolorem.','2005-08-20 18:40:27'),
('9','12','9','Et quia libero aut vitae minus. Rerum a blanditiis debitis sit nam. Veniam quasi aut autem ratione dolorem. Sunt quo similique dolorem odit totam sint sed.','2013-03-19 04:10:10'),
('10','11','8','Suscipit dolore voluptas et sit vero et sint. Rem ut ratione voluptatum assumenda nesciunt ea. Quas qui qui atque ut. Similique et praesentium non voluptate iure. Eum aperiam officia quia dolorem.','2005-03-21 18:40:27'),
('11','12','59','Et quia libero aut vitae minus. Rerum a blanditiis debitis sit nam. Veniam quasi aut autem ratione dolorem. Sunt quo similique dolorem odit totam sint sed.','2013-06-19 04:10:10'),
('12','10','12','Praesentium molestias quia aut odio. Est quis eius ut animi optio molestiae. Amet tempore sequi blanditiis in est.','1976-05-22 14:38:15'),
('13','11','12','Molestiae laudantium quibusdam porro est alias placeat assumenda. Ut consequatur rerum officiis exercitationem eveniet. Qui eum maxime sed in.','1996-04-27 00:23:37'),
('14','12','25','Quo asperiores et id veritatis placeat. Aperiam ut sit exercitationem iste vel nisi fugit quia. Suscipit labore error ducimus quaerat distinctio quae quasi.','1989-05-13 22:39:47'),
('15','15','13','Earum sunt quia sed harum modi accusamus. Quia dolor laboriosam asperiores aliquam quia. Sint id quasi et cumque qui minima ut quo. Autem sed laudantium officiis sit sit.','1997-09-30 00:06:14'),
('16','20','16','Aut enim sint voluptas saepe. Ut tenetur quos rem earum sint inventore fugiat. Eaque recusandae similique earum laborum.','1977-10-15 23:26:40'),
('17','20','15','Nisi rerum officiis officiis aut ad voluptates autem. Dolor nesciunt eum qui eos dignissimos culpa iste. Atque qui vitae quos odit inventore eum. Quam et voluptas quia amet.','1977-10-13 19:40:32'),
('18','20','16','Consequatur ut et repellat non voluptatem nihil veritatis. Vel deleniti omnis et consequuntur. Et doloribus reprehenderit sed earum quas velit labore.','1998-05-24 10:09:36'),
('19','17','20','Iste deserunt in et et. Corrupti rerum a veritatis harum. Ratione consequatur est ut deserunt dolores.','1993-01-30 15:51:38'),
('20','18','21','Dicta non inventore autem incidunt accusamus amet distinctio. Aut laborum nam ab maxime. Maxime minima blanditiis et neque. Et laboriosam qui at deserunt magnam.','1996-05-19 14:18:39'),
('21','21','19','Amet ad dolorum distinctio excepturi possimus quia. Adipisci veniam porro ipsum ipsum tempora est blanditiis. Magni ut quia eius qui.','1998-08-12 04:42:34');

INSERT INTO `orders` (`ordered_products`, `ship_to`, `shipped_by`, `payment_method`, `paid`, `ship_to_address`) VALUES 
('{"item1": "product", "item2": "product"}', '1', '3', 'cash', 'no', 'Moscow, 111674 Vertoletchikov Street'),
('{"item1": "product", "item2": "product"}', '1', '3', 'credit_card', 'no', 'Samara, 343124'),
('{"item1": "product", "item2": "product"}', '1', '5', 'cash', 'yes', NULL),
('{"item1": "product"}', '45', '6', 'paypal', 'yes', 'Moscow, 343253'),
('{"item1": "product"}', '45', '7', 'paypal', 'yes', NULL),
('{"item1": "product", "item2": "product"}', '3', '8', 'credit_card', 'yes', 'Omsk, Petrova Street 87, kv. 90'),
('{"item1": "product"}', '4', '8', 'credit_card', 'yes', 'Kiev, ul Vatuz 4, kv. 4, 334987'),
('{"item1": "product", "item2": "product", "item3": "product", "item4": "product", "item5": "product"}', '50', '8', 'credit_card', 'yes', 'Moscow, ul Krasnoy Armee 13, kv. 98, 111154'),
('{"item1": "product"}', '4', '8', 'paypal', 'yes', 'Moscow, Tverskaya Street 11, 111098'),
('{"item1": "product", "item2": "product"}', '5', '9', 'cash', 'no', 'Moscow, Tverskaya Street 11, 111098'),
('{"item1": "product", "item2": "product"}', '6', '9', 'credit_card', 'yes', 'Moscow, Tverskaya Street 11, 111098'),
('{"item1": "product"}', '12', '9', 'credit_card', 'yes', 'Omsk, ul. Petrenkova 12, kv. 93, 420885'),
('{"item1": "product"}', '12', '10', 'credit_card', 'yes', 'St. Petersburg, Dvortsovaya Ploshad" 53, kv. 32, 798371'),
('{"item1": "product", "item2": "product"}', '15', '11', 'credit_card', 'no', 'St. Petersburg, Dvortsovaya Ploshad" 53, kv. 32, 798371'),
('{"item1": "product", "item2": "product"}', '17', '15', 'credit_card', 'yes', NULL),
('{"item1": "product", "item2": "product", "item3": "product", "item4": "product", "item5": "product"}', '54', '13', 'credit_card', 'yes', 'St. Petersburg, Dvortsovaya Ploshad" 53, kv. 32, 798371'),
('{"item1": "product", "item2": "product", "item3": "product", "item4": "product", "item5": "product"}', '35', '23', 'credit_card', 'yes', 'Moscow, ul Solnechnaya 3, kv. 389, 178193'),
('{"item1": "product"}', '38', '20', 'paypal', 'yes', 'Kalimov, ul. Moscovskaya 87, kv. 78, 987467'),
('{"item1": "product"}', '41', '21', 'paypal', 'yes', NULL),
('{"item1": "product"}', '42', '18', 'paypal', 'yes', 'Kalimov, ul. Moscovskaya 87, kv. 78, 987467'),
('{"item1": "product"}', '14', '19', 'paypal', 'yes', 'Smolensk, Leningradskaya Street 58, kv. 34'),
('{"item1": "product"}', '7', '1', 'credit_card', 'yes', 'Smolensk, Leningradskaya Street 58, kv. 34'),
('{"item1": "product", "item2": "product"}', '8', '2', 'credit_card', 'no', NULL),
('{"item1": "product", "item2": "product"}', '9', '3', 'credit_card', 'yes', NULL),
('{"item1": "product", "item2": "product", "item3": "product"}', '10', '4', 'credit_card', 'yes', 'Peterburg, ul. Sentesfdg 45, kv. 78, 478932'),
('{"item1": "product", "item2": "product", "item3": "product", "item4": "product"}', '11', '5', 'credit_card', 'yes', 'Peterburg, ul. Sentesfdg 45, kv. 78, 478932'),
('{"item1": "product", "item2": "product"}', '12', '6', 'paypal', 'yes', 'Kemerov, ul Koroleva 43, kv. 543, 334987'),
('{"item1": "product", "item2": "product", "item3": "product", "item4": "product", "item5": "product"}', '38', '9', 'credit_card', 'yes', NULL),
('{"item1": "product", "item2": "product"}', '12', '7', 'paypal', 'no', 'Moscow, 111674 Vertoletchikov Street'),
('{"item1": "product", "item2": "product"}', '14', '11', 'paypal', 'yes', NULL),
('{"item1": "product", "item2": "product"}', '15', '12', 'credit_card', 'yes', NULL),
('{"item1": "product", "item2": "product", "item3": "product", "item4": "product", "item5": "product"}', '1', '13', 'credit_card', 'yes', 'Kemerov, ul Koroleva 43, kv. 543, 334987'),
('{"item1": "product", "item2": "product"}', '15', '14', 'cash', 'no', NULL),
('{"item1": "product", "item2": "product"}', '17', '26', 'cash', 'yes', NULL),
('{"item1": "product", "item2": "product"}', '17', '27', 'credit_card', 'yes', 'Smolensk, Leningradskaya Street 58, kv. 34');


/* 
Скрипты выборок 
*/

-- Находим пользователя 
SELECT * FROM users 
WHERE id = 1; 

-- Находим пользователей, которые еще и продавцы
SELECT username, email
FROM users 
WHERE is_seller = 'yes';

-- Находим пользователей-продавцов, которые указали, что их родной город - Таганрог 
SELECT 
	users.username as seller, 
	hometown
FROM users
 JOIN users_profiles as profiles ON users.id = profiles.user_id
WHERE is_seller = 'yes' AND hometown = 'Taganrog';

-- Количество продавцов на сайте, адрес магазина которых указан как Москва (может отличаться от адреса самого пользователя)
SELECT COUNT(*) 
FROM sellers
WHERE contact_address RLIKE 'Moscow';

-- кто из предыдуших указал свой адрес пользователя тоже как Москва
SELECT COUNT(*) 
FROM sellers
	JOIN users_profiles on sellers.is_user = users_profiles.user_id
WHERE contact_address RLIKE 'Moscow' and hometown = 'Moscow';

-- Выборка данных по продавцу и о его магазине
SELECT users.username, email, real_name, birthday, hometown, telephone_number, interests, shop_name, contact_address
  FROM users
    JOIN users_profiles as profiles ON users.id = profiles.user_id
    JOIN sellers ON users.id = sellers.is_user
  WHERE users.id = 3;

-- Выборка товаров магазина, которым владеет юзер с id 9
SELECT product_name, product_photo, price, category, customisation, shipped, shop_name, contact_address
  FROM products
    JOIN sellers ON products.seller_id = sellers.id     
  WHERE sellers.is_user = 9;
  
-- Выборка товаров магазина, которым владеет юзер с id 9, для которых есть доставка
SELECT product_name, product_photo, price, category, customisation, shipped, shop_name, contact_address
  FROM products
    JOIN sellers ON products.seller_id = sellers.id     
  WHERE sellers.is_user = 9 AND shipped = 'yes';

-- Выборка сколько товаров у каждого продавца, у кого больше всех товаров в начале
SELECT 
COUNT(id) AS prod_count, 
seller_id
  FROM products
  GROUP BY seller_id
  ORDER BY prod_count DESC;

-- Выборка подписчиков на всех продавцов, сортировка по количеству на какой-либо магазин
SELECT 
shop_name, 
COUNT(*) AS total_subscribers
  FROM sellers
    JOIN users_subscribed_tos ON (sellers.id = users_subscribed_tos.seller_id)
  GROUP BY sellers.id
  ORDER BY total_subscribers DESC;
  
-- Выборка на сколько магазинов подписаны юзеры, сортировка по убыванию кол-ва
SELECT 
username, 
COUNT(*) AS subscribed_tos
  FROM users
    JOIN users_subscribed_tos ON (users.id = users_subscribed_tos.user_id)
  GROUP BY users.id
  ORDER BY subscribed_tos DESC;

-- Выборка подписавшихся на магазин пользователя с id 9
SELECT users_profiles.username, real_name, 
    CASE (gender)
         WHEN 'male' THEN 'M'
         WHEN 'female' THEN 'F'
    END AS gender, 
    TIMESTAMPDIFF(YEAR, birthday, NOW()) AS age,
    hometown
  FROM users_profiles
	JOIN users ON users_profiles.user_id = users.id
  WHERE users.id IN
	( SELECT user_id
	FROM users_subscribed_tos
		JOIN sellers ON (users_subscribed_tos.seller_id = sellers.id)
        WHERE sellers.is_user = 9)
;

-- Выбираем заказы пользователя 
SELECT * FROM orders
WHERE 
	ship_to = 1 -- отправка юзеру с id 1
ORDER BY shipped_by;
;

-- Выбираем заказы пользователя в магазине 3
SELECT ordered_products, shop_name, paid
FROM orders
	JOIN sellers
    ON orders.shipped_by = sellers.id
WHERE 
	ship_to = 1 -- отправка юзеру с id 1
    AND shipped_by = 3
;

-- Выбираем только заказы пользователей с подтверждённой оплатой, группировка по пользователю
SELECT ship_to, COUNT(*) as 'total num of orders'
	FROM orders
	WHERE paid = 'yes'
GROUP BY ship_to;
  
-- 10 пользователей с наибольшим количеством заказов
SELECT users.username, real_name, COUNT(*) AS total_orders
  FROM users
    JOIN users_profiles ON users.id = users_profiles.user_id
    JOIN orders ON users.id = orders.ship_to
  GROUP BY users.id
  ORDER BY total_orders DESC
  LIMIT 10;

-- Выборка воркшопов по месяцам
SELECT 
	COUNT(id) 
	, MONTHNAME(date) AS month_name
FROM academy
WHERE activity_type = 'workshop'
GROUP BY month_name
; 
    
-- Сообщения к пользователю
SELECT username, body, created_at
  FROM messages
    JOIN users ON users.id = messages.to_user_id
  WHERE messages.from_user_id = 1;
  
-- Сообщения от владельца магазина 17
SELECT shop_name, users.username, body, created_at
  FROM messages
    JOIN sellers ON messages.from_user_id = sellers.is_user
    JOIN users ON messages.from_user_id = users.id
  WHERE sellers.id = 17;
  
  
  
/* Представления, хранимые процедуры и триггеры; */

-- Процедура, выбирающая подписчиков магазина
DROP PROCEDURE IF EXISTS view_subscribers;
DELIMITER //
CREATE PROCEDURE view_subscribers(in sellers_id INT)
BEGIN
SELECT users_profiles.username, real_name, 
    TIMESTAMPDIFF(YEAR, birthday, NOW()) AS age,
    hometown
  FROM users_profiles
	JOIN users ON users_profiles.user_id = users.id
  WHERE users.id IN
	( SELECT user_id
	FROM users_subscribed_tos
		JOIN sellers ON (users_subscribed_tos.seller_id = sellers.id)
        WHERE sellers.id = sellers_id)
;
END//
DELIMITER ; 

CALL view_subscribers(2);

-- Процедура приглашет пользователя на мероприятие (это часть на сайте называется Академия)
	-- если он подписан на продавца, который это организует
	-- дату не проверяем, рассылка приглашений происходит 1 раз при создании события. Да, те кто подпишется на мастера после рассылки, но до мероприятия в пролете и приглашения не получат. 
  
DROP PROCEDURE IF EXISTS activity_invitation;
DELIMITER //
CREATE PROCEDURE activity_invitation(IN activity_id INT)
  BEGIN
	SELECT users.id
	FROM users
		JOIN users_subscribed_tos sub 
		    ON (users.id = sub.user_id )
		JOIN sellers
			ON (sub.seller_id = sellers.id)
		JOIN academy
			ON (sellers.id = academy.author)
	WHERE academy.id = activity_id
	ORDER BY users.id;
  END// 
DELIMITER ; 

CALL activity_invitation(3); -- кого зовем читать статью с id 3 ?


-- Триггер для проверки того, что у незавершенного конкурса не указан победитель
DROP TRIGGER IF EXISTS check_winner_update;
DELIMITER //
CREATE TRIGGER check_winner_update BEFORE UPDATE ON contests
FOR EACH ROW
BEGIN
    IF NEW.finishes > NOW() AND NEW.winner IS NOT NULL
    THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'You cannot add the winner yet!';
    END IF;
END//
DELIMITER ;

DROP TRIGGER IF EXISTS check_winner_insert;
DELIMITER //
CREATE TRIGGER check_winner_insert BEFORE INSERT ON contests
FOR EACH ROW
BEGIN
    IF NEW.finishes > NOW() AND NEW.winner IS NOT NULL
    THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'You cannot add the winner yet!';
    END IF;
END//
DELIMITER ;

-- Триггер для проверки того, что дата мероприятия указана в будущем 
DROP TRIGGER IF EXISTS check_activity_date_insert;
DELIMITER //
CREATE TRIGGER check_activity_date_insert BEFORE INSERT ON academy
FOR EACH ROW
BEGIN
    IF NEW.date < NOW() THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'You cannot add an activity with a past date';
    END IF;
END//
DELIMITER ;
-- INSERT INTO `db_livemaster`.`academy` (`activity_type`, `date`, `count`, `author`) VALUES ('workshop', '2000-12-12 10:00:00', '4', '3'); 

-- Триггер для проверки того, что дата мероприятия указана в будущем, если вдруг кто-то хитрый потом ее поменять решит
DROP TRIGGER IF EXISTS check_activity_date_update;
DELIMITER //
CREATE TRIGGER check_activity_date_update BEFORE UPDATE ON academy
FOR EACH ROW
BEGIN
    IF NEW.date < NOW() THEN
		 SIGNAL SQLSTATE '45000' 
         SET MESSAGE_TEXT = 'You cannot update this activity with a past date';
    END IF;
END//
DELIMITER ;


-- Представление покажет фотографию пользователя
CREATE OR REPLACE VIEW view_photos
AS 
  SELECT users.id, users.username, photos.photo_name
  FROM users
    JOIN users_profiles profiles 
		ON users.id = profiles.user_id
	JOIN photos  
		ON profiles.photo_id = photos.id
;

SELECT *
FROM view_photos
WHERE id = 1;
  
-- Представление и функция с ним для расчета коэфицента среднего числа заказов каждого пользователя, то есть заказы пользователя / кол-во всех заказов. Найдем самого транжиру :)
CREATE OR REPLACE VIEW user_orders
AS 
	SELECT ship_to, COUNT(*)
	FROM orders
    GROUP BY ship_to;
    
SELECT *
FROM user_orders
WHERE ship_to = 45;

DROP FUNCTION IF EXISTS avg_orders;
DELIMITER //
CREATE FUNCTION avg_orders(user_id INT)
RETURNS FLOAT READS SQL DATA
  BEGIN
    DECLARE total_orders INT;
    DECLARE user_orders INT;

    SET total_orders = 
      (SELECT COUNT(*) 
        FROM orders);
        
    SET user_orders = (
		SELECT COUNT(*)
		FROM user_orders
		WHERE ship_to = user_id);
      
    RETURN user_orders / total_orders;
  END// 
DELIMITER ; 

SELECT TRUNCATE(avg_orders(45), 2);


-- Представление и функция с ним для расчета коэфицента среднего числа заказов на каждый магазин мастера
CREATE OR REPLACE VIEW sold_products
AS 
	SELECT shipped_by, COUNT(*)
	FROM orders
    GROUP BY shipped_by;
SELECT *
FROM sold_products
WHERE shipped_by = 8;
DROP FUNCTION IF EXISTS avg_sold_orders;
DELIMITER //
CREATE FUNCTION avg_sold_orders(seller_id INT)
RETURNS FLOAT READS SQL DATA
  BEGIN
    DECLARE total_orders INT;
    DECLARE seller_orders INT;
    SET total_orders = 
      (SELECT COUNT(*) 
        FROM orders);
    SET seller_orders = (
		SELECT COUNT(*)
		FROM sold_products
		WHERE shipped_by = seller_id);
    RETURN seller_orders / total_orders;
  END// 
DELIMITER ; 

SELECT TRUNCATE(avg_sold_orders(9), 2);
