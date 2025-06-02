

-----SCALAR FUNCTION-----

CREATE TABLE Products_fn (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50),
    Price DECIMAL(10,2),
    Rating INT -- 1 to 5 stars
);
 
INSERT INTO Products_fn VALUES
(1, 'Pizza', 500.00, 5),
(2, 'Burger', 250.00, 4),
(3, 'Pasta', 350.00, 3),
(4, 'Fries', 150.00, 2),
(5, 'Salad', 200.00, 4),
(6, 'Soda', 100.00, 1);


CREATE TABLE Order_fn (
    OrderID INT PRIMARY KEY,
    ProductID INT,
    Quantity INT,
    DiscountPercent INT,
    OrderDate DATE,
    FOREIGN KEY (ProductID) REFERENCES Products_fn(ProductID)
);
 
INSERT INTO Order_fn VALUES
(101, 1, 2, 10, '2024-04-01'),
(102, 2, 1, 0,  '2024-04-10'),
(103, 3, 3, 5,  '2024-04-15'),
(104, 5, 2, 15, '2024-04-25'),
(105, 1, 1, 0,  '2024-05-01');


CREATE TABLE Coupons_fn (
    CouponCode VARCHAR(20) PRIMARY KEY,
    DiscountPercent INT,
    IsActive BIT
);
 
INSERT INTO Coupons_fn VALUES
('NEW50', 50, 1),
('SAVE10', 10, 1),
('EXPIRED', 30, 0);

CREATE TABLE Customers_fn (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    City VARCHAR(50)
);

INSERT INTO Customers_fn VALUES
(1, 'Amit Sharma', 'Delhi'),
(2, 'Sneha Patel', 'Mumbai'),
(3, 'Raj Verma', 'Bangalore');


SELECT * FROM Products_fn;
SELECT * FROM Order_fn;
SELECT * FROM Coupons_fn;
SELECT * FROM Customers_fn;
SELECT * FROM Student;


-- 1. Create a scalar function to return the full name of a customer.

SELECT * FROM Customers_sp;

alter FUNCTION fn_GetFullName (@CustomerID INT)
RETURNS VARCHAR(100)
AS
BEGIN

--DECLARE @fullName varchar(100)
DECLARE @DOMAIN VARCHAR(100)


--SELECT  @fullName = FirstName + ' | ' + LastName FROM Customers_sp
--where CustomerID = @CustomerID


SELECT  @DOMAIN = CAST(CustomerID AS VARCHAR) + ' ' + EmailID FROM Customers_sp
where CustomerID = @CustomerID

--return @fullName
RETURN @DOMAIN

END;

select DBO.fn_GetFullName(2)

SELECT *, DBO.fn_GetFullName(CustomerID)  FROM Customers_sp;

--Write a function that returns the square of a number.

CREATE FUNCTION fn_square (
    @ProductID INT
)
RETURNS int
AS
BEGIN
	DECLARE @Rating int

	SELECT @Rating = Rating * Rating FROM Products_fn
	WHERE ProductID = @ProductID

	RETURN @Rating
END

SELECT dbo.fn_square(2); 


--Create a function that returns the year from a given date.

CREATE FUNCTION fn_year (
    @OrderID INT
)
RETURNS int
AS
BEGIN
	DECLARE @OrderDate int

	SELECT @OrderDate = year(OrderDate) FROM Order_fn
	WHERE OrderID = @OrderID

	RETURN @OrderDate
END

SELECT dbo.fn_year(101); 

--Create a function that returns 'Pass' if marks >= 35, else 'Fail'.

ALTER FUNCTION fn_passfail (
    @StudentID int
)
RETURNS varchar(10)
AS
BEGIN
    DECLARE @Marks varchar(10)
    SELECT @Marks = IIF(Marks >= 75, 'Pass', 'Fail') FROM Student WHERE StudentID = @StudentID

    RETURN @Marks 
END;

SELECT dbo.fn_passfail(1) as result; 
SELECT *, DBO.fn_passfail (StudentID) as result  FROM Student;

--Create a scalar function that calculates the final price after applying a given discount percent to a product price.

CREATE FUNCTION fn_GetFinalOrderPrice (
    @ProductID INT,
    @Quantity INT,
    @DiscountPercent INT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @price DECIMAL(10,2)
    SELECT @price = Price FROM Products_fn WHERE ProductID = @ProductID

    DECLARE @total DECIMAL(10,2)
    SET @total = @price * @Quantity

    RETURN @total - (@total * @DiscountPercent / 100)
END;

SELECT dbo.fn_GetFinalOrderPrice(2, 5, 20); 

--Create a stored procedure that takes an OrderID, calculates the final price after discount using the function from Q1, and displays it.

select * from Order_fn;
select * from Products_fn;

CREATE PROCEDURE sp_GetOrderFinalAmount
    @OrderID INT
AS
BEGIN
    DECLARE @ProductID INT, @Quantity INT, @Discount INT

    SELECT @ProductID = ProductID,
           @Quantity = Quantity,
           @Discount = DiscountPercent
    FROM Order_fn
    WHERE OrderID = @OrderID

    SELECT dbo.fn_GetFinalOrderPrice(@ProductID, @Quantity, @Discount) AS FinalPrice
END;

EXEC sp_GetOrderFinalAmount @OrderID = 101;

--Create a table-valued function that returns all orders where the total amount after discount exceeds a given threshold.


SELECT * FROM Order_fn;

CREATE FUNCTION fn_GetOrdersAboveAmount(
    @MinAmount DECIMAL(10,2)
)
RETURNS TABLE
AS
RETURN
(
 SELECT o.OrderID, o.ProductID, o.Quantity, o.DiscountPercent, dbo.fn_GetFinalOrderPrice(o.ProductID, o.Quantity, o.DiscountPercent) AS FinalPrice FROM Order_fn o
 where dbo.fn_GetFinalOrderPrice(o.ProductID, o.Quantity, o.DiscountPercent) > @MinAmount
 );

SELECT * FROM dbo.fn_GetOrdersAboveAmount(500);

--Create a stored procedure that uses the function from Q3 to list orders above ₹500.

CREATE PROCEDURE sp_order
AS
BEGIN
	SELECT * FROM dbo.fn_GetOrdersAboveAmount(500);
END;

EXEC sp_order;

--Create a scalar function that returns the tax amount (e.g., 18% GST) for a given price.

select * from Products_fn;

alter FUNCTION fn_TAX(
    @ProductID int
)
RETURNS int
AS
BEGIN
	DECLARE @Price int

	SELECT @Price = Price + (Price * 18 / 100) FROM Products_fn
	WHERE ProductID = @ProductID

	RETURN @Price

END;

SELECT dbo.fn_TAX(1);
SELECT *, dbo.fn_TAX(ProductID) from Products_fn;

--Create a stored procedure that calculates the total bill amount including discount and tax for a given order.

CREATE PROCEDURE get_totalBillAmount(
@orderId int
)
AS 
BEGIN
	   DECLARE @price int , @quantity int , @Discount int , @Total int 

	   SELECT @price = P.Price,
			  @quantity = O.Quantity,
		      @Discount = O.DiscountPercent
	   FROM Order_fn O JOIN Products_fn P  on O.ProductID = P.ProductID
	   where OrderID = @orderId;
 
		--SELECT @Total = ((@price * @quantity)- @Discount ) + (((@price * @quantity)- @Discount ) * 0.18) ;
 
		SET @total = (@price * @quantity) * (1 - @Discount / 100.0) * 1.18;

		SELECT @price AS Price, @quantity AS Quantity, @Discount as Discount,  @Total as FinalPrice
END;
 
EXEC  get_totalBillAmount @orderId = 101;

--Create a table-valued function that returns all products with a price greater than the average product price.

CREATE FUNCTION dbo.GetAboveAveragePricedProducts()
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM Products_fn
    WHERE Price > (SELECT AVG(Price) FROM Products)
);

--Create a stored procedure that lists all such above-average priced products using the function from Q7.

CREATE PROCEDURE dbo.ShowAboveAveragePricedProducts
AS
BEGIN
    SELECT * FROM dbo.GetAboveAveragePricedProducts();
END;

--Create a scalar function to return a rating category ("High", "Medium", "Low") based on a numeric rating input.

CREATE FUNCTION dbo.GetRatingCategory(@Rating FLOAT)
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @Category VARCHAR(10);
    IF @Rating >= 4.5
        SET @Category = 'High';
    ELSE IF @Rating >= 3.0
        SET @Category = 'Medium';
    ELSE
        SET @Category = 'Low';
    RETURN @Category;
END;

--Create a stored procedure that uses the above function to show each product and its rating category based on a Rating column.

CREATE PROCEDURE dbo.ShowProductRatings
AS
BEGIN
    SELECT 
        ProductID,
        ProductName,
        Rating,
        dbo.GetRatingCategory(Rating) AS RatingCategory
    FROM Products_fn;
END;

--Create a table-valued function that returns all orders with more than 2 quantities and less than 10% discount.

CREATE FUNCTION dbo.GetFilteredOrders()
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM Orders_fn
    WHERE Quantity > 2 AND Discount < 0.10
);

--Create a scalar function that converts a numeric value to a formatted currency string (e.g., ₹1,000.00).

CREATE FUNCTION dbo.FormatCurrency(@Amount MONEY)
RETURNS VARCHAR(50)
AS
BEGIN
    RETURN '₹' + FORMAT(@Amount, 'N2');
END;

--Create a stored procedure that uses this currency-formatting function to display all order totals in INR format.

--CREATE PROCEDURE dbo.ShowOrderTotalsInINR
--AS
--BEGIN
--    SELECT 
--        OrderID,
--        CustomerID,
--        TotalAmount,
--        dbo.FormatCurrency(TotalAmount) AS FormattedAmount
--    FROM Orders_fn;
--END;

--Create a table-valued function that lists orders placed on a specific date (pass date as parameter).

CREATE FUNCTION dbo.GetOrdersByDate(@OrderDate DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM Orders_fn
    WHERE CAST(OrderDate AS DATE) = @OrderDate
);

--Create a stored procedure that calls the above function to get daily order reports.

CREATE PROCEDURE dbo.DailyOrderReport
    @ReportDate DATE
AS
BEGIN
    SELECT * FROM dbo.GetOrdersByDate(@ReportDate);
END;

EXEC dbo.DailyOrderReport @ReportDate = '2025-06-01';

--Create a scalar function that returns the number of days between order date and current date.

CREATE FUNCTION dbo.DaysSinceOrder(@OrderDate DATE)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(DAY, @OrderDate, GETDATE());
END;

SELECT dbo.DaysSinceOrder('2025-05-01') AS DaysPassed;


--Create a stored procedure that shows all orders older than 30 days using the above function.

CREATE PROCEDURE dbo.OrdersOlderThan30Days
AS
BEGIN
    SELECT *
    FROM Orders_fn
    WHERE dbo.DaysSinceOrder(OrderDate) > 30;
END;

--Create a table-valued function that returns all products that have not been ordered yet.

CREATE FUNCTION dbo.fn_UnorderedProducts()
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM Products_fn
    WHERE ProductID NOT IN (
        SELECT DISTINCT ProductID FROM Order_fn
    )
);

SELECT * FROM dbo.fn_UnorderedProducts();

--Create a scalar function that returns a delivery charge based on total order amount (e.g., free delivery above ₹500).

CREATE FUNCTION dbo.fn_DeliveryCharge(@Total DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @charge DECIMAL(10,2);
    SET @charge = CASE WHEN @Total >= 500 THEN 0 ELSE 30 END;
    RETURN @charge;
END;

SELECT dbo.fn_DeliveryCharge(400) AS Delivery;

--Create a stored procedure that computes total amount + delivery charge using functions from Q1 and Q19.

CREATE PROCEDURE dbo.sp_OrderFinalAmount
AS
BEGIN
    SELECT 
        o.OrderID,
        p.ProductName,
        o.Quantity,
        p.Price,
        o.DiscountPercent,
        (o.Quantity * p.Price * (1 - o.DiscountPercent/100.0)) AS Total,
        dbo.fn_DeliveryCharge((o.Quantity * p.Price * (1 - o.DiscountPercent/100.0))) AS DeliveryCharge,
        (o.Quantity * p.Price * (1 - o.DiscountPercent/100.0)) 
            + dbo.fn_DeliveryCharge((o.Quantity * p.Price * (1 - o.DiscountPercent/100.0))) AS FinalAmount
    FROM Order_fn o
    JOIN Products_fn p ON o.ProductID = p.ProductID;
END;

EXEC dbo.sp_OrderFinalAmount;

--Return star emoji representation of product rating

CREATE FUNCTION fn_RatingStars (@Rating INT)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN REPLICATE('⭐', @Rating)
END;

SELECT ProductName, Rating, dbo.fn_RatingStars(Rating) AS Stars FROM Products_fn;

--Return product category based on price range

CREATE FUNCTION fn_ProductCategory (@Price DECIMAL(10,2))
RETURNS VARCHAR(20)
AS
BEGIN
    RETURN CASE
        WHEN @Price >= 400 THEN 'Premium'
        WHEN @Price >= 200 THEN 'Mid-Range'
        ELSE 'Economy'
    END
END;

SELECT ProductName, Price, dbo.fn_ProductCategory(Price) AS Category FROM Products_fn;

--Return if product is a "Best Seller" (based on order count > 2)

CREATE FUNCTION fn_IsBestSeller (@ProductID INT)
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @Count INT;
    SELECT @Count = COUNT(*) FROM Order_fn WHERE ProductID = @ProductID;

    RETURN CASE WHEN @Count > 2 THEN 'Yes' ELSE 'No' END;
END;

SELECT ProductID, ProductName, dbo.fn_IsBestSeller(ProductID) AS BestSeller FROM Products_fn;





















--TABLE-VALUED FUNCTION

SELECT * FROM Student;

ALTER FUNCTION fn_GetData (@Grade VARCHAR(10))
RETURNS TABLE
AS
RETURN
(
SELECT *, (Age + Marks) as aa FROM Student WHERE Grade = @Grade
)

SELECT * FROM DBO.fn_GetData ('B');

--Return all orders that used a product with 4-star rating or higher

CREATE FUNCTION fn_HighRatedProductOrders()
RETURNS TABLE
AS
RETURN (
    SELECT o.* FROM Order_fn o
    JOIN Products_fn p ON o.ProductID = p.ProductID
    WHERE p.Rating >= 4
);

SELECT * FROM dbo.fn_HighRatedProductOrders();

--Return orders where actual discount amount exceeds ₹100

CREATE FUNCTION fn_OrdersWithHighDiscount()
RETURNS TABLE
AS
RETURN (
    SELECT o.OrderID, p.ProductName, o.Quantity, o.DiscountPercent,
           (p.Price * o.Quantity * o.DiscountPercent / 100.0) AS DiscountAmount
    FROM Order_fn o
    JOIN Products_fn p ON o.ProductID = p.ProductID
    WHERE (p.Price * o.Quantity * o.DiscountPercent / 100.0) > 100
);


SELECT * FROM dbo.fn_OrdersWithHighDiscount();

--Products never ordered AND having rating >= 3

CREATE FUNCTION fn_UnorderedHighRatedProducts()
RETURNS TABLE
AS
RETURN (
    SELECT * FROM Products_fn
    WHERE Rating >= 3 AND ProductID NOT IN (SELECT DISTINCT ProductID FROM Order_fn)
);

SELECT * FROM dbo.fn_UnorderedHighRatedProducts();

--Return all products ordered more than once

CREATE FUNCTION fn_ProductsOrderedMultipleTimes()
RETURNS TABLE
AS
RETURN (
    SELECT p.ProductID, p.ProductName, COUNT(o.OrderID) AS OrderCount
    FROM Products_fn p
    JOIN Order_fn o ON p.ProductID = o.ProductID
    GROUP BY p.ProductID, p.ProductName
    HAVING COUNT(o.OrderID) > 1
);

SELECT * FROM dbo.fn_ProductsOrderedMultipleTimes();

--Return all orders with final amount (after discount) between two values

CREATE FUNCTION fn_OrdersWithinAmountRange(
    @MinAmount DECIMAL(10,2),
    @MaxAmount DECIMAL(10,2)
)
RETURNS TABLE
AS
RETURN (
    SELECT o.OrderID, p.ProductName, o.Quantity,
           p.Price * o.Quantity * (1 - o.DiscountPercent / 100.0) AS FinalAmount
    FROM Order_fn o
    JOIN Products_fn p ON o.ProductID = p.ProductID
    WHERE p.Price * o.Quantity * (1 - o.DiscountPercent / 100.0) BETWEEN @MinAmount AND @MaxAmount
);

SELECT * FROM dbo.fn_OrdersWithinAmountRange(200, 1000);

--Return all orders made in a particular month

CREATE FUNCTION fn_OrdersByMonth(@Month INT, @Year INT)
RETURNS TABLE
AS
RETURN (
    SELECT * FROM Order_fn
    WHERE MONTH(OrderDate) = @Month AND YEAR(OrderDate) = @Year
);

SELECT * FROM dbo.fn_OrdersByMonth(4, 2024);

--List all coupons that were not used in any order

CREATE FUNCTION fn_UnusedCoupons()
RETURNS TABLE
AS
RETURN (
    SELECT * FROM Coupons_fn
    WHERE CouponCode NOT IN (SELECT DISTINCT CouponCode FROM Order_fn WHERE CouponCode IS NOT NULL)
);

--Return product with highest price in each rating group

CREATE FUNCTION fn_HighestPricedPerRating()
RETURNS TABLE
AS
RETURN (
    SELECT p.*
    FROM Products_fn p
    WHERE p.Price = (
        SELECT MAX(Price) FROM Products_fn WHERE Rating = p.Rating
    )
);

SELECT * FROM dbo.fn_HighestPricedPerRating();
