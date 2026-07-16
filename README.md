# 📚 Library Management System — SQL Project

## 📌 Overview
This project simulates a complete **Library Management System (LMS)** database using **PostgreSQL**, covering everything from schema design and relational integrity (foreign keys) to real-world business operations — CRUD operations, CTAS (Create Table As), stored procedures, and analytical reporting.

The project demonstrates end-to-end database management: designing normalized tables, enforcing relationships, writing operational queries, and generating branch-level performance reports.

---

## 🎯 Objectives
- Design a normalized relational schema for a library system with proper foreign key relationships
- Perform CRUD operations (Create, Read, Update, Delete) on core tables
- Use CTAS to generate derived summary tables
- Write a stored procedure to automate the book return process
- Identify overdue books and members with pending returns
- Generate branch-wise performance and revenue reports
- Identify top-performing employees and active members

---

## 🗂️ Dataset & Files

| File | Description |
|---|---|
| `books.csv` | Book catalog — ISBN, title, category, rental price, status, author, publisher |
| `branch.csv` | Library branch details — branch ID, manager, address, contact |
| `employees.csv` | Employee records — ID, name, position, salary, assigned branch |
| `members.csv` | Library member records — ID, name, address, registration date |
| `issued_status.csv` | Book issue transactions — who issued what, when, and by which employee |
| `return_status.csv` | Book return transactions — linked to issued records |
| `Liberary_Management_Schema.sql` | DDL script — table schema creation + foreign key constraints |
| `Liberary_Management_System_Solution.sql` | DML/DQL script — all 17 business task queries and procedures |

---

## 🛠️ Tools & Tech Stack
- **PostgreSQL** – Database design & querying
- **SQL Concepts used:** `JOIN` (INNER/LEFT), `GROUP BY` + `HAVING`, `CTAS`, `Stored Procedures (PL/pgSQL)`, `Foreign Key Constraints`, Date arithmetic (`CURRENT_DATE`, `INTERVAL`), Aggregate functions (`SUM`, `COUNT`)

---

## 🧱 Database Schema (ERD Logic)

```
branch (1) ────< employees (many)
employees (1) ──< issued_status (many)
members (1) ────< issued_status (many)
books (1) ──────< issued_status (many)
issued_status (1) ─< return_status (1)
```

**Tables:**

```sql
branch(branch_id PK, manager_id, branch_address, contact_no)
employees(emp_id PK, emp_name, position, salary, branch_id FK)
books(isbn PK, book_title, category, rental_price, status, author, publisher)
members(member_id PK, member_name, member_address, reg_date)
issued_status(issued_id PK, issued_member_id FK, issued_book_name, issued_date, issued_book_isbn FK, issued_emp_id FK)
return_status(return_id PK, issued_id FK, return_book_name, return_date, return_book_isbn)
```

All foreign key relationships are enforced via `ALTER TABLE ... ADD CONSTRAINT` to maintain referential integrity across issued/returned books, members, employees, and branches.

---

## 🔍 Business Tasks Solved
			

### 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

```sql
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Monkingbird', 'Classis', 6.00, 'Yes', 'Harper Lee', 'J.B. Lippincott & Co. ');
```

### 2: Update an Existing Member's Address

```sql
UPDATE members
SET member_address = '125 Left New York'
WHERE member_id = 'C101';
```

### 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121';
```

### 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

```sql
SELECT 
	* 
FROM issued_status
WHERE issued_emp_id = 'E101';
```

### 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

```sql
SELECT 
	issued_emp_id,
	COUNT(*) AS total_book_issued
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(*)>1;
```

### 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

```sql
CREATE TABLE book_cnt AS
SELECT 
	b.isbn, 
	b.book_title, 
	COUNT(*) AS total_book_issued 
FROM books b
JOIN issued_status i
ON b.isbn = i.issued_book_isbn
GROUP BY b.book_title, b.isbn;
```

### 7. Retrieve All Books in a Specific Category:

```sql
SELECT 
	*
FROM books
WHERE category = 'Classic';
```

### 8: Find Total Rental Income by Category:

```sql
SELECT 
	b.category, 
	SUM(b.rental_price), 
	COUNT(*)
FROM books b
JOIN issued_status i
ON b.isbn = i.issued_book_isbn
GROUP BY b.category;
```

### 9: List Members Who Registered in the Last 180 Days:

```sql
SELECT 
	* 
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '5 year';
```

### 10: List Employees with Their Branch Manager's Name and their branch details:

```sql
SELECT 
	e.emp_id, 
	e.emp_name,
	e.position,
	e.salary, 
	b.*, 
	e1.emp_name AS branch_manager
FROM employees e
JOIN branch b
ON e.branch_id = b.branch_id
JOIN employees e1
ON e1.emp_id = b.manager_id;
```

### 11. Create a Table of Books with Rental Price Above a Certain Threshold:

```sql
CREATE TABLE expensive_book AS
SELECT 
	* 
FROM books
WHERE rental_price>=7;
```

### 12: Retrieve the List of Books Not Yet Returned

```sql
SELECT 
	* 
FROM issued_status i
LEFT JOIN return_status r 
ON r.issued_id = i.issued_id
WHERE r.return_id IS NULL;
```

### 13: Identify Members with Overdue Books ( Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

```sql
SELECT 
	ist.issued_member_id, 
	m.member_name, 
	b.book_title, 
	ist.issued_date,
	rt.return_date,
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
ORDER BY 1;
```

### 14: Update Book Status on Return (Write a query to update the status of books in the books table to "Yes" when they are returned based on entries in the return_status table).

```sql
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
```

### 15: Branch Performance Report ( Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.)

```sql
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
```

### 16: CTAS: Create a Table of Active Members ( Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.)

```sql
CREATE TABLE acive_member 
AS
SELECT 
	* 
FROM members
WHERE member_id IN (SELECT 
					DISTINCT issued_member_id 
					FROM issued_status
     				WHERE issued_date>= CURRENT_DATE - INTERVAL '3 MONTH');
```

### 17: Find Employees with the Most Book Issues Processed (Write a query to find the top 3 employees who have processed the most book issues.) Display the employee name, number of books processed, and their branch.

```sql
SELECT 
	e.emp_name, 
	b.*, 
	COUNT(ist.issued_id) AS total_book_issued
FROM issued_status ist
JOIN employees e
ON e.emp_id = ist.issued_emp_id
JOIN books bk
ON ist.issued_book_isbn = bk.isbn
JOIN branch b
ON e.branch_id = b.branch_id
GROUP BY 1,2
```


---

## ⚙️ Key Feature: Automated Return Procedure

A **PL/pgSQL stored procedure** (`return_book`) automates the return workflow in a single call:

```sql
CALL return_book('RS125', 'IS136');
```

This procedure:
1. Inserts a new record into `return_status` with the current date
2. Looks up the returned book's ISBN from `issued_status`
3. Updates the book's `status` back to available in the `books` table
4. Raises a confirmation notice with the book title

---

## 💡 Key Insights
- Branch-wise reporting reveals which branches generate the highest rental revenue and issue the most books.
- Overdue analysis (30-day threshold) flags members with pending returns — useful for automated reminder systems.
- The stored procedure approach shows how the return process can be handled as a single transactional operation instead of manual multi-step updates.
- Employee performance ranking highlights top processors of book issues, useful for staffing and incentive decisions.

---

## 🚀 How to Run
1. Install PostgreSQL (or use any SQL-compatible database).
2. Run `Liberary_Management_Schema.sql` first to create all tables and foreign key constraints.
3. Import the CSV files into their respective tables:
   ```sql
   \copy branch FROM 'branch.csv' DELIMITER ',' CSV HEADER;
   \copy employees FROM 'employees.csv' DELIMITER ',' CSV HEADER;
   \copy books FROM 'books.csv' DELIMITER ',' CSV HEADER;
   \copy members FROM 'members.csv' DELIMITER ',' CSV HEADER;
   \copy issued_status FROM 'issued_status.csv' DELIMITER ',' CSV HEADER;
   \copy return_status FROM 'return_status.csv' DELIMITER ',' CSV HEADER;
   ```
4. Run `Liberary_Management_System_Solution.sql` section-by-section to reproduce all business task solutions.

> ⚠️ Note: Load tables in this order — `branch` → `employees` → `books` → `members` → `issued_status` → `return_status` — to respect foreign key dependencies.

---

## 📁 Repository Structure
```
├── data/
│   ├── books.csv
│   ├── branch.csv
│   ├── employees.csv
│   ├── issued_status.csv
│   ├── members.csv
│   └── return_status.csv
├── Liberary_Management_Schema.sql     # Schema + constraints
├── Liberary_Management_System_Solution.sql    # Business queries + procedure
└── README.md                              # Project documentation
```

---

## 👤 Author
**Shamsul Hoda**
Data Analyst | SQL • Python • Power BI • Advanced Excel
📧 Email : shamsbusiness4632@gmail.com
🔗 Linkedin Profile : ![LinkedIn](https://www.linkedin.com/in/shamsulhoda-s4632)

---

⭐ If you found this project useful, consider giving it a star on GitHub!
