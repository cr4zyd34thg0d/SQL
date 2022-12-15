USE pos;

CALL proc_FillUnitPrice();

CALL proc_FillOrderTotal();

CALL proc_FillMVCustomerPurchases();

/*************************************#1&#2*****************************/
/* create table #1&2*/
DROP TABLE IF EXISTS `priceChangeLog`;
CREATE TABLE `priceChangeLog` (
  `ID` INT unsigned NOT NULL AUTO_INCREMENT,
  `oldPrice` DECIMAL(6,2) DEFAULT NULL,
  `newPrice` DECIMAL(6,2) DEFAULT NULL,
  `changeTimestamp` TIMESTAMP DEFAULT NULL,
  `productid`INT DEFAULT NULL,
  PRIMARY KEY (`ID`),
  CONSTRAINT `priceChangelog_ibfk_1` FOREIGN KEY (`productid`) REFERENCES `product` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/********************************************************************
***************************-----END-----*****************************
********************************************************************/

/*************************************#3*****************************/
/*before an update to the table set oldPrice #3*/
DELIMITER //

CREATE OR REPLACE TRIGGER product_price_after_update 
AFTER UPDATE
  ON product FOR EACH ROW 

BEGIN

IF !(NEW.currentPrice = OLD.currentPrice) THEN
  INSERT INTO priceChangeLog 
    SET
    `oldPrice` = OLD.currentPrice,
    `newPrice` = NEW.currentPrice,
    productid = OLD.`ID`;
  END IF;
END;
//
DELIMITER ;
/********************************************************************
***************************-----END-----*****************************
********************************************************************/

/*************************************#4*****************************/
/*Update unitPrice before insert or update to product table price #4*/
DELIMITER //
    create or replace procedure proc_UpdateMVproduct(in prodID int)
        modifies sql data
        begin
            update mv_ProductBuyers pb
            left join
                (select product.ID as productID, product.name as productName, group_concat(distinct c.ID, ' ', c.firstName, ' ',c.lastName order by c.ID) as customers
                    from product
                    left join orderLine oL on product.ID = oL.productID
                    left join `order` o on oL.orderID = o.ID
                    left join customer c on o.customerID = c.ID
                    group by product.ID) p on pb.productID = p.productID
                set 
                    pb.productID = p.productID,
                    pb.productName = p.productName,
                    pb.customers = p.customers
                where pb.productID = prodID;          
        end; //
        DELIMITER ;

DELIMITER //
create or replace trigger trig_orderLine_price_after_update
        after update on orderLine
            for each row
        begin
            update `order` ord
                left join
                    (select orderID, sum(lineTotal) lt
                        from orderLine
                        group by orderID) ol on ord.ID = ol.orderID
                set orderTotal = ol.lt
                where ord.ID = new.orderID;

            set @prodID = new.productID;
            call proc_UpdateMVproduct(@prodID);  

            update product pd
                left join
                    (select productID, quantity
                        from orderLine) ol on pd.ID = ol.productID
                set pd.qtyOnHand = pd.qtyOnHand + (old.quantity - new.quantity)
                where pd.ID = new.productID;              
end; //
DELIMITER ;

DELIMITER //
create or replace trigger trig_orderLine_price_insert_insert
        AFTER INSERT on orderLine
            for each row
        begin
            update `order` ord
                left join
                    (select orderID, sum(lineTotal) lt
                        from orderLine
                        group by orderID) ol on ord.ID = ol.orderID
                set orderTotal = ol.lt
                where ord.ID = new.orderID;

            set @prodID = new.productID;
            call proc_UpdateMVproduct(@prodID);  

            update product pd
                left join
                    (select productID, quantity
                        from orderLine) ol on pd.ID = ol.productID
                set pd.qtyOnHand = pd.qtyOnHand + (quantity - new.quantity)
                where pd.ID = new.productID;              
end; //
DELIMITER ;


DELIMITER //
CREATE OR REPLACE TRIGGER trig_unitPrice_Before_Insert 
BEFORE INSERT
  ON orderLine FOR EACH ROW
BEGIN
DECLARE in_price decimal(6,2);
SELECT currentPrice INTO @in_price FROM product WHERE product.ID = NEW.productID;
SET NEW.unitPrice = @in_price;
END; //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE TRIGGER trig_unitPrice_before_Update 
BEFORE UPDATE
  ON orderLine FOR EACH ROW
BEGIN
DECLARE in_price decimal(6,2);
SELECT currentPrice INTO @in_price FROM product WHERE product.ID = NEW.productID;
SET NEW.unitPrice = @in_price;
END; //
DELIMITER ;
/********************************************************************
***************************-----END-----*****************************
********************************************************************/

/*************************************#5*****************************/
/* keep OrderTotal up to date after update or insert to orderLine #5*/
DELIMITER //
 
CREATE OR REPLACE 
TRIGGER unitPrice_after_insert_on_orderLine
AFTER INSERT
  ON orderLine FOR EACH ROW 
BEGIN
    UPDATE `order` ORD
    LEFT JOIN (SELECT orderID, SUM(lineTotal) linetl
    FROM orderLine
    GROUP BY orderID) orderl ON ORD.ID = orderl.orderID
    SET orderTotal = orderl.linetl
    WHERE ORD.ID = NEW.orderID;
  END;
//

CREATE OR REPLACE 
TRIGGER unitPrice_after_update_on_orderLine
AFTER UPDATE
  ON orderLine FOR EACH ROW 
BEGIN
    UPDATE `order` ORD
    LEFT JOIN (SELECT orderID, SUM(lineTotal) linetl
    FROM orderLine
    GROUP BY orderID) orderl ON ORD.ID = orderl.orderID
    SET orderTotal = orderl.linetl
    WHERE ORD.ID = NEW.orderID;
  END;
//

CREATE OR REPLACE 
TRIGGER unitPrice_after_delete_on_orderLine
AFTER DELETE
  ON orderLine FOR EACH ROW 
BEGIN
    UPDATE `order` ORD
    LEFT JOIN (SELECT orderID, SUM(lineTotal) linetl
    FROM orderLine
    GROUP BY orderID) orderl ON ORD.ID = orderl.orderID
    SET orderTotal = orderl.linetl
    WHERE ORD.ID = OLD.orderID;
  END;
//
DELIMITER ;

/********************************************************************
***************************-----END-----*****************************
********************************************************************/

/*************************************#6*****************************/
DELIMITER //
CREATE OR REPLACE PROCEDURE proc_mv_customerPurchase_customer (
        IN ID INT,
        IN FN VARCHAR(64),
        IN LN VARCHAR(32)
)

BEGIN
        UPDATE mv_CustomerPurchases
        SET firstName = FN, lastName = LN
        WHERE mv_CustomerPurchases.ID = ID;
END; //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE
TRIGGER tr_mv_customer_from_customer_after_update AFTER UPDATE 
ON customer FOR EACH ROW
BEGIN
        SET @newID = NEW.ID;
        SET @newFN = NEW.firstName;
        SET @newLN = NEW.lastName;

CALL proc_mv_customerPurchase_customer(@newID,@newFN,@newLN);
END; //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE PROCEDURE proc_mv_customerpurchase_product()
BEGIN 
UPDATE mv_CustomerPurchases, v_CustomerPurchases
SET mv_CustomerPurchases.products = v_CustomerPurchases.products
WHERE v_CustomerPurchases.ID = mv_CustomerPurchases.ID;
END; //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE TRIGGER trig_mv_customer_from_product_after_update
AFTER UPDATE ON product FOR each ROW 
BEGIN
call proc_mv_customerpurchase_product ();
END; //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE TRIGGER trig_mvproductbuyers_after_update AFTER UPDATE 
ON customer FOR each ROW 
BEGIN
SET @newID = ID;
SET @newname = `name`;
call proc_mv_productbuyers (@newID,@newname);
END ; //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE PROCEDURE proc_mv_productbuyers_product()
BEGIN
UPDATE mv_ProductBuyers, v_ProductBuyers
SET mv_ProductBuyers.productName = v_ProductBuyers.productName
WHERE v_ProductBuyers.productID = mv_ProductBuyers.productID;
END; //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE TRIGGER trig_mv_productbuyers_product_after_update AFTER UPDATE
ON product FOR each ROW 
BEGIN
CALL proc_mv_productbuyers_product();
END; //
DELIMITER ;

/********************************************************************
***************************-----END-----*****************************
********************************************************************/

/*************************************#7*****************************/
DELIMITER //
CREATE OR REPLACE
TRIGGER qty_before_insert
BEFORE INSERT
ON orderLine FOR EACH ROW
BEGIN
        IF NEW.quantity IS NULL THEN
        SET NEW.quantity = 1;
END IF;
        IF NEW.quantity > (SELECT qtyOnHand
        FROM product
        WHERE ID = NEW.productID) THEN
        signal sqlstate '45000'
        SET message_text = 'Sorry, we do not have enough stock for that product.';
        ELSE UPDATE product
        SET qtyOnHand =(qtyOnHand - NEW.quantity)
        WHERE product.ID = NEW.productID;
END IF;
END; //
DELIMITER ;
DELIMITER //
CREATE OR REPLACE
TRIGGER qty_before_update
BEFORE UPDATE
ON orderLine FOR EACH ROW
BEGIN
        IF NEW.quantity IS NULL THEN
        SET NEW.quantity = 1;
END IF;
        IF NEW.quantity > (SELECT qtyOnHand
        FROM product
        WHERE ID = NEW.productID) THEN
        signal sqlstate '45000'
        SET message_text = 'Sorry, we do not have enough stock for that product.';
        ELSE UPDATE product
        SET qtyOnHand =(qtyOnHand - NEW.quantity)
        WHERE product.ID = NEW.productID;
END IF;
END; //
DELIMITER ;
DELIMITER //
CREATE OR REPLACE
TRIGGER qty_before_delete
BEFORE DELETE
ON orderLine FOR EACH ROW
BEGIN
        UPDATE product
        SET qtyOnHand =(qtyOnHand - OLD.quantity)
        WHERE product.ID = OLD.productID;
END; //
DELIMITER ;

/********************************************************************
***************************-----END-----*****************************
********************************************************************
UPDATE product SET currentPrice = 1.11 WHERE ID = 0;UPDATE product SET name = "abc" WHERE ID = 1;
INSERT INTO `order` (ID,customerID) VALUES (9760,2);
INSERT INTO orderLine (orderID,productID,quantity) VALUES (9760,1,2); 
UPDATE product SET currentPrice = 2.22 WHERE ID = 2;
UPDATE orderLine SET quantity = 1 WHERE orderID = 9760;
INSERT INTO `order` (ID,customerID) VALUES (9761,2);
INSERT INTO orderLine (orderID, productID,quantity) VALUES (9761,2,3);
INSERT INTO orderLine (orderID, productID,quantity) VALUES (9761,1,2);