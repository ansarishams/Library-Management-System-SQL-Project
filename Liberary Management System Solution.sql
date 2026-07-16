-- PROJECT TASK
SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM return_status;
SELECT * FROM issued_status;
SELECT * FROM members;
--  Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Monkingbird', 'Classis', 6.00, 'Yes', 'Harper Lee', 'J.B. Lippincott & Co. ');

-- Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Left New York'
WHERE member_id = 'C101';

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id = 'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101'

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT issued_emp_id, COUNT(*) AS total_book_issued
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(*)>1;

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_cnt AS
SELECT b.isbn, b.book_title, COUNT(*) AS total_book_issued 
FROM books b
JOIN issued_status i
ON b.isbn = i.issued_book_isbn
GROUP BY b.book_title, b.isbn;

-- Task 7. Retrieve All Books in a Specific Category:
SELECT * FROM books
WHERE category = 'Classic';

-- Task 8: Find Total Rental Income by Category:
SELECT b.category, SUM(b.rental_price), COUNT(*)
FROM books b
JOIN issued_status i
ON b.isbn = i.issued_book_isbn
GROUP BY b.category;

-- Task 9: List Members Who Registered in the Last 180 Days:

SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '5 year';

-- Task 10: List Employees with Their Branch Manager's Name and their branch details:

SELECT e.emp_id, e.emp_name,e.position, e.salary, b.*, e1.emp_name AS branch_manager
FROM employees e
JOIN branch b
ON e.branch_id = b.branch_id
JOIN employees e1
ON e1.emp_id = b.manager_id;


-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:

CREATE TABLE expensive_book AS
SELECT * FROM books
WHERE rental_price>=7;

-- Task 12: Retrieve the List of Books Not Yet Returned

SELECT * FROM issued_status i
LEFT JOIN return_status r 
ON r.issued_id = i.issued_id
WHERE r.return_id IS NULL;


-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

SELECT ist.issued_member_id, m.member_name, b.book_title, ist.issued_date,rt.return_date,
	CURRENT_DATE - ist.issued_date AS over_due_days
FROM issued_status ist
JOIN members m
ON ist.issued_member_id = m.member_id
JOIN books b
ON b.isbn = ist.issued_book_isbn
LEFT JOIN return_status rt
ON rt.issued_id = ist.issued_id
WHERE rt.issued_id IS NULL
AND (CURRENT_DATE - ist.issued_date)>30
ORDER BY 1


-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).


CREATE OR REPLACE PROCEDURE return_book(p_return_id VARCHAR(50), p_issued_id VARCHAR(50))
LANGUAGE plpgsql
AS $$

DECLARE
	v_isbn VARCHAR(100);
	v_book_name VARCHAR(100);

BEGIN
	INSERT INTO return_status(return_id, issued_id, return_date)
	VALUES(p_return_id, p_issued_id, CURRENT_DATE);

	SELECT 
		issued_book_isbn,
		issued_book_name
		INTO
		v_isbn,
		v_book_name
	FROM issued_status
	WHERE issued_id = p_issued_id;

	UPDATE books
	SET status = 'yes'
	WHERE isbn = v_isbn;

	RAISE NOTICE 'Thank you for returning the book: %', v_book_name; 
END;
$$

CALL return_book('RS125','IS136');


-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.


CREATE TABLE branch_report
AS
SELECT b.branch_id, 
	   b.manager_id,
	   COUNT(ist.issued_id) AS total_book_issued,
	   COUNT(rt.return_id) AS total_book_returned,
	   SUM(bk.rental_price) AS total_revenue
FROM issued_status ist
JOIN employees e
ON e.emp_id = issued_emp_id
JOIN branch b
ON b.branch_id = e.branch_id
JOIN books bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN return_status rt
ON ist.issued_id = rt.issued_id
GROUP BY b.branch_id, b.manager_id;

SELECT * FROM branch_report



-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.
CREATE TABLE acive_member 
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
					DISTINCT issued_member_id 
				FROM issued_status
     			WHERE issued_date>= CURRENT_DATE - INTERVAL '3 MONTH');




-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.


SELECT e.emp_name, b.*, COUNT(ist.issued_id) AS total_book_issued
FROM issued_status ist
JOIN employees e
ON e.emp_id = ist.issued_emp_id
JOIN books bk
ON ist.issued_book_isbn = bk.isbn
JOIN branch b
ON e.branch_id = b.branch_id
GROUP BY 1,2


