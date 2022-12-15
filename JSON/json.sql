
	
	SELECT JSON_ARRAYAGG(JSON_OBJECT(
	'Customer ID', customer.ID, 
	'First Name', customer.firstName,
	'Last Name', customer.lastName,
	'Email',customer.email,
	'Address',customer.address1,
	'ORDERS',(SELECT JSON_ARRAYAGG(JSON_OBJECT(
	'Order No',`order`.ID,
	'Order Placed Date',`order`.datePlaced,
	'Shipped Date',`order`.dateShipped,
	'Grand Total',(
	select sum(orderLine.quantity*product.currentPrice) from orderLine 
	INNER JOIN product ON orderLine.productID = product.ID
	where orderLine.orderID=`order`.ID
	),
	'PRODUCTS',(SELECT JSON_ARRAYAGG(JSON_OBJECT(
	'Product ID',product.ID,
	'Product Name',product.`name`,
	'Unit Price',product.currentPrice,
	'Qty',orderLine.quantity,
	'Sub. Total (Price)',product.qtyOnHand
	
	)) 
	FROM orderLine  
	INNER JOIN product ON orderLine.productID = product.ID
	WHERE orderLine.orderID=`order`.ID
	)
	
	
	)) FROM `order`  WHERE `order`.ID=customer.ID)
	
	
	
	)) from customer;
		