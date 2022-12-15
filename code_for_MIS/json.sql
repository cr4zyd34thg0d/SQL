use pos;

/*    "Customer ID": 0,
    "First Name": "Roxie",
    "Last Name": "Green",
    "Orders": 0,
        (
            "Order ID": 0,
            "Order Total": 1,
            "Items"
        ) */
SELECT JSON_ARRAYAGG(
    JSON_OBJECT(
        "Customer ID", c.id
        "First Name", c.firstName,
        "Last Name", c.lastName,
        "Orders", JSON_EXTRACT(
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    "Order ID", o.id,
                    "Order Total", o.totalPrice,
                    "Items", JSON_EXTRACT(
                    )
                    FROM `Order`
                    WHERE o.customerID = c.id
                    ...
                    "Items", JSON_EXTRACT(
                        SELECT JSON_ARRAYAGG(
                            JSON_OBJECT(
                                ...
                            )
                            FROM OrderLine ol
                            WHERE ol.orderID = o.id
                    )
                )
            )  FROM `Order` o
            WHERE o.customerID = c.id
        )
    )
) FROM Customer c
WHERE c.id < 4027;