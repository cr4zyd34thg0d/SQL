USE pos;

DROP VIEW IF EXISTS `v_CustomerNames`;
DROP VIEW IF EXISTS `v_Customers`;
DROP VIEW IF EXISTS `v_ProductBuyers`;
DROP VIEW IF EXISTS `v_CustomerPurchases`;
DROP TABLE IF EXISTS `mv_ProductBuyers`;
DROP TABLE IF EXISTS `mv_CustomerPurchases`;
/*DROP INDEX IF EXISTS `idx_CustomerEmail` ON customer;
DROP INDEX IF EXISTS `idx_ProductName` ON product;
/************************* VIEW 1 ***********************/
CREATE VIEW `v_CustomerNames`
AS SELECT 
  lastName AS LN, 
  firstName AS FN 
FROM 
  pos.customer 
ORDER BY 
  lastName;
/************************* VIEW 1 ***********************/

/************************* VIEW 2 ***********************/
CREATE VIEW `v_Customers` 
AS SELECT 
  c.`ID` AS `customer_number`, 
  c.`firstName` AS `first_name`, 
  c.`lastName` AS `last_name`, 
  c.`address1` AS `street1`, 
  c.`address2` AS `street2`,
  ci.city,
  ci.`state`,
  ci.zip AS `zip_code`, 
  c.email
FROM pos.customer c
JOIN pos.city ci ON c.zip = ci.zip;
/************************* VIEW 2 ***********************/

/************************* VIEW 3 ***********************/
CREATE VIEW `v_ProductBuyers` 
AS SELECT 
  product.`ID` AS `productID`,
  product.`name` AS `productName`,
GROUP_CONCAT(DISTINCT
  CONCAT_WS(' ',
  customer.`ID`,
  customer.firstName,
  customer.lastName)
ORDER BY customer.`ID` SEPARATOR ',') AS customers
FROM pos.product
LEFT JOIN pos.orderLine ON orderLine.productID = product.`ID`
LEFT JOIN pos.`order` ON orderLine.orderID = `order`.`ID`
LEFT JOIN pos.customer ON customer.`ID` = `order`.customerID
GROUP BY
  productID
Order BY
  productID;
/************************* VIEW 3 ***********************/

/************************* VIEW 4 ***********************/
CREATE VIEW `v_CustomerPurchases` 
AS SELECT
customer.`ID`,
customer.firstName,
customer.lastName,
GROUP_CONCAT(DISTINCT
  product.`ID`,
  ' ',
  product.name
ORDER BY product.`ID` SEPARATOR '|') AS products
FROM pos.customer
LEFT JOIN pos.`order` ON `order`.customerID = customer.`ID`
LEFT JOIN pos.orderLine ON `order`.`ID` = orderLine.orderID
LEFT JOIN pos.product ON orderLine.productID = product.`ID`
GROUP BY
  customer.`ID`
Order BY
  customer.`ID`;
/************************* VIEW 1 ***********************/

/************************* VIEW 5 ***********************/
CREATE TABLE `mv_ProductBuyers` AS
SELECT * FROM pos.`v_ProductBuyers`;

CREATE TABLE `mv_CustomerPurchases` AS 
SELECT * FROM pos.`v_CustomerPurchases`;
/************************* VIEW 5 ***********************/

/************************* VIEW 6 ***********************/
CREATE OR REPLACE INDEX `idx_CustomerEmail` ON customer(email);
/************************* VIEW 6 ***********************/

/************************* VIEW 7 ***********************/
CREATE OR REPLACE INDEX `idx_ProductName` ON product(name);
/************************* VIEW 7 ***********************/