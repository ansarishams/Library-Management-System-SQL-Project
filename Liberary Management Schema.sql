      -- Liberary Management System

CREATE TABLE branch(
	branch_id VARCHAR(100) PRIMARY KEY,
	manager_id VARCHAR(100) ,	
	branch_address VARCHAR(100),	
	contact_no VARCHAR(100)	

)

CREATE TABLE employees(
	emp_id	VARCHAR(20)	PRIMARY KEY,
	emp_name VARCHAR(50),	
	position VARCHAR(50),	
	salary INT,	
	branch_id VARCHAR(50)	--FK

)

CREATE TABLE books(
	isbn VARCHAR(100) PRIMARY KEY,
	book_title VARCHAR(100),	
	category VARCHAR(50),	
	rental_price FLOAT,	
	status VARCHAR(20),	
	author VARCHAR(50),	
	publisher VARCHAR(100)	

)

CREATE TABLE issued_status(
	issued_id VARCHAR(50) PRIMARY KEY,
	issued_member_id VARCHAR(50),	--FK
	issued_book_name VARCHAR(100),	
	issued_date	DATE,	
	issued_book_isbn VARCHAR(50),  --FK	
	issued_emp_id VARCHAR(50)	--FK

)

CREATE TABLE members(
	member_id VARCHAR(50) PRIMARY KEY,
	member_name VARCHAR(100),	
	member_address VARCHAR(100),	
	reg_date DATE	
)


CREATE TABLE return_status(
	return_id VARCHAR(50) PRIMARY KEY,
	issued_id VARCHAR(50),	    --FK
	return_book_name VARCHAR(50),	
	return_date	DATE,	
	return_book_isbn VARCHAR(50)	--FK
)

-- FOREIGN KEY
ALTER TABLE issued_status
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);


ALTER TABLE issued_status
ADD CONSTRAINT fk_books
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status
ADD CONSTRAINT fk_employees
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE employees
ADD CONSTRAINT fk_branch
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);

ALTER TABLE return_status
ADD CONSTRAINT fk_issued_status
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id);
