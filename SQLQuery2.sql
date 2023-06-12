
--Challenge Description: 

--You are working on a database for a library management system. Your task is to write SQL queries, create triggers, CTEs, user-defined functions, and views to implement various functionalities within the system.
CREATE SCHEMA library;
GO 
CREATE TABLE library.Books (
BookID INT PRIMARY KEY, 
Title VARCHAR (255) NOT NULL, 
Author VARCHAR(255) NOT NULL,
PublicationYear VARCHAR(255) NOT NULL,
Status VARCHAR(255) NOT NULL);

CREATE TABLE library.Members(
MemberID INT PRIMARY KEY,
Name VARCHAR(255) NOT NULL,
Address VARCHAR (255) NOT NULL,
ContactNumber VARCHAR (20) NOT NULL
);
 
CREATE TABLE library.Loans(
LoanID INT PRIMARY KEY,
BookID INT FOREIGN KEY REFERENCES library.Books (BookID),
MemberID INT FOREIGN KEY REFERENCES library.members(MemberID),
LoanDate DATE,
ReturnDate DATE 
);

--Schema Details: Consider the following simplified schema for the library management system:

--Books (BookID, Title, Author, PublicationYear, Status)
--Members (MemberID, Name, Address, ContactNumber)
--Loans (LoanID, BookID, MemberID, LoanDate, ReturnDate)

--Challenge Tasks:

-- Write a trigger that automatically updates the "Status" column in the "Books" table whenever a book is loaned or returned. The "Status" should be set to 'Loaned' if the book is loaned and 'Available' if the book is returned.
CREATE TRIGGER library.bookStatus
ON library.loans
AFTER INSERT, UPDATE ,DELETE 
AS 
BEGIN 
    IF EXISTS (SELECT 1 FROM inserted) 
    BEGIN
        UPDATE library.Books
        SET Status = 'Loaned'
        WHERE BookID IN (SELECT BookID FROM inserted);
    END
    IF EXISTS (SELECT 1 FROM deleted) 
    BEGIN
        UPDATE library.Books
        SET Status = 'Available'
        WHERE BookID IN (SELECT BookID FROM deleted)
          AND BookID NOT IN (SELECT BookID FROM library.Loans);
    END
END;

--Create a CTE that retrieves the names of all members who have borrowed at least three books.

WITH BorrowedBooks AS (
    SELECT MemberID, COUNT(*) AS NumBorrowed
    FROM library.Loans
    GROUP BY MemberID
    HAVING COUNT(*) >= 3
)
SELECT M.Name
FROM library.Members AS M
JOIN BorrowedBooks AS BB ON M.MemberID = BB.MemberID;

--Write a user-defined function that calculates the overdue days for a given loan. The function should accept the LoanID as a parameter and return the number of days the loan is overdue.
CREATE FUNCTION CalculateOverdueDays (@LoanID INT)
RETURNS INT
AS
BEGIN
    DECLARE @DueDate DATE, @ReturnDate DATE, @OverdueDays INT;

    SELECT @DueDate = ReturnDate
    FROM library.Loans
    WHERE LoanID = @LoanID;

    SELECT @ReturnDate = GETDATE();

    SET @OverdueDays = DATEDIFF(DAY, @DueDate, @ReturnDate);

    RETURN CASE WHEN @OverdueDays > 0 THEN @OverdueDays ELSE 0 END;
END;

--Create a view that displays the details of all overdue loans, including the book title, member name, and number of overdue days.
CREATE VIEW OverdueLoansView
AS
    SELECT L.LoanID, B.Title AS BookTitle, M.Name AS MemberName, DATEDIFF(DAY, L.ReturnDate, GETDATE()) AS OverdueDays
    FROM library.Loans AS L
    JOIN library.Books AS B ON L.BookID = B.BookID
    JOIN library.Members AS M ON L.MemberID = M.MemberID
    WHERE L.ReturnDate < CAST(GETDATE() AS DATE);


SELECT *
FROM OverdueLoansView;

--Write a trigger that prevents a member from borrowing more than three books at a time. If a member tries to borrow a book when they already have three books on loan, the trigger should raise an error and cancel the operation.

CREATE TRIGGER PreventExcessiveBorrowing
ON library.Loans
FOR INSERT
AS
BEGIN
    DECLARE @MemberID INT, @NumBooksOnLoan INT;

    SELECT @MemberID = MemberID FROM inserted;
    
    SELECT @NumBooksOnLoan = COUNT(*) FROM library.Loans WHERE MemberID = @MemberID;

    IF @NumBooksOnLoan >= 3
    BEGIN
        RAISERROR('Not allowed to bollow more than 3 books.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;

