USE pos;

ALTER TABLE `orderLine`
  ADD IF NOT EXISTS `unitPrice` decimal(6,2) DEFAULT NULL;

ALTER TABLE `orderLine`
  ADD COLUMN IF NOT EXISTS `lineTotal` decimal(7,2)
  GENERATED ALWAYS AS (`quantity` * `unitPrice`) VIRTUAL;

ALTER TABLE `order`
  ADD IF NOT EXISTS `orderTotal` decimal(8,2) DEFAULT NULL;

ALTER TABLE `customer`
  DROP IF EXISTS `phone`;

ALTER TABLE `order`
  DROP CONSTRAINT IF EXISTS `order_ibfk_1`;

DROP TABLE IF EXISTS `status`;

ALTER TABLE `order`
  DROP COLUMN IF EXISTS `status`;

DELIMITER //
CREATE OR REPLACE PROCEDURE proc_FillUnitPrice ()
BEGIN
    UPDATE orderLine, product
    SET orderLine.unitPrice = product.currentPrice
    WHERE orderLine.productID = product.ID
    AND orderLine.unitPrice IS NULL;
END
//
DELIMITER ;

DELIMITER //

CREATE OR REPLACE PROCEDURE proc_FillOrderTotal ()
BEGIN
    UPDATE `order` ORD
    LEFT JOIN (SELECT orderID, SUM(lineTotal) linetl
    FROM orderLine
    GROUP BY orderID) orderl ON ORD.ID = orderl.orderID
    SET orderTotal = orderl.linetl
    WHERE ORD.ID = orderl.orderID;
  END;

//
DELIMITER ;

DELIMITER //
CREATE OR REPLACE PROCEDURE proc_FillMVCustomerPurchases ()
BEGIN
    TRUNCATE TABLE mv_CustomerPurchases;
    INSERT INTO mv_CustomerPurchases
    SELECT * FROM v_CustomerPurchases;
END;
//
DELIMITER ;
/*
DELIMITER //
CREATE OR REPLACE PROCEDURE proc_FillMVProductBuyers ()
BEGIN
    TRUNCATE TABLE mv_ProductBuyers;
    INSERT INTO mv_ProductBuyers
    SELECT * FROM v_ProductBuyers;
END;
//
DELIMITER ;