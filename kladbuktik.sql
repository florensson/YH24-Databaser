/*
Skapa butiken först, detta är draft 1 och kan behöva förbättras.
Men i SQL så innefattar detta alla vi ska göra.
*/

CREATE DATABASE Klädbutik;
USE Klädbutik;

-- Skapa Kunder-tabellen
CREATE TABLE Kunder (
    KundID INT AUTO_INCREMENT PRIMARY KEY,
    Namn VARCHAR(100) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    Registreringsdatum TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Skapa Produkter-tabellen
CREATE TABLE Produkter (
    ProduktID INT AUTO_INCREMENT PRIMARY KEY,
    Namn VARCHAR(100) NOT NULL,
    Pris DECIMAL(10,2) NOT NULL CHECK (Pris > 0),
    Kategori VARCHAR(50) NOT NULL
);

-- Skapa Beställningar-tabellen
CREATE TABLE Beställningar (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    KundID INT NOT NULL,
    Datum TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (KundID) REFERENCES Kunder(KundID)
);

-- Skapa Orderrader-tabellen
CREATE TABLE Orderrader (
    OrderradID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    ProduktID INT NOT NULL,
    Antal INT NOT NULL CHECK (Antal > 0),
    Pris DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Beställningar(OrderID),
    FOREIGN KEY (ProduktID) REFERENCES Produkter(ProduktID)
);


-- Lektion 2

-- Infoga data
INSERT INTO Kunder (Namn, Email) VALUES
('Anna Andersson', 'anna@email.com'),
('Erik Svensson', 'erik@email.com');
('Lisa Berg', 'lisa@email.com');

INSERT INTO Produkter (Namn, Pris, Kategori) VALUES
('T-shirt', 199.99, 'Kläder'),
('Jeans', 499.99, 'Kläder'),
('Sneakers', 899.99, 'Skor');

-- Hämtar data
SELECT * FROM Kunder;
SELECT Namn, Email FROM Kunder;

-- Where filterar data
SELECT * FROM Kunder WHERE Namn = 'Anna Andersson';
SELECT * FROM Produkter WHERE Pris > 500; -- Priset är över 500kr

-- Order by, sortera datan
SELECT * FROM Produkter ORDER BY Pris ASC;
SELECT * FROM Kunder ORDER BY Registreringsdatum DESC;

/*
Om det bråkar med delete och update så kan vi använda: 
SET SQL_SAFE_UPDATES = 0;

Om du inte gillar det och de risker som finns kan du 
UPDATE Kunder SET Email = 'anna.new@email.com' WHERE KundID = 1;
där vi använder PK för att lösa det.
*/

-- uppdatera data
UPDATE Kunder SET Email = 'anna.new@email.com' WHERE Namn = 'Anna Andersson';

-- ta bort data
DELETE FROM Kunder WHERE Namn = 'Erik Svensson';

/*
Ett ännu bättre sätt är att:
*/
START TRANSACTION;  -- Börjar en transaktion

UPDATE Kunder 
SET Email = 'anna.ny@email.com' 
WHERE KundID = 1;

SELECT * FROM Kunder WHERE KundID = 1;  -- Kolla om ändringen ser rätt ut

COMMIT;  -- Spara ändringen permanent

ROLLBACK;  -- Ångra ändringen

-- Lektion 3

/*
Lägger till lite mer för att det ska bli något mer att kolla på sitället för null
*/
INSERT INTO Beställningar (KundID, Datum) VALUES
(1, '2024-03-01'),
(1, '2024-03-10'),
(2, '2024-03-05'),
(3, '2024-03-07'),
(3, '2024-03-10'),
(3, '2024-03-12');


INSERT INTO Orderrader (OrderID, ProduktID, Antal, Pris) VALUES
(1, 1, 2, 199.99),  -- Kund 1 köper 2 T-shirts
(1, 3, 1, 899.99),  -- Kund 1 köper 1 par Sneakers
(2, 2, 1, 499.99),  -- Kund 1 köper 1 par Jeans
(3, 1, 1, 199.99),  -- Kund 2 köper 1 T-shirt
(4, 2, 1, 499.99),  -- Kund 3 köper 1 par Jeans
(5, 3, 1, 899.99),  -- Kund 3 köper 1 par Sneakers
(6, 1, 3, 199.99);  -- Kund 3 köper 3 T-shirts


-- inner join
SELECT Kunder.Namn, Beställningar.OrderID
FROM Kunder
INNER JOIN Beställningar ON Kunder.KundID = Beställningar.KundID;

-- Left join
SELECT Kunder.Namn, Beställningar.OrderID
FROM Kunder
LEFT JOIN Beställningar ON Kunder.KundID = Beställningar.KundID;

-- Group by, räknar antal beställningar per kund
SELECT KundID, COUNT(OrderID) AS AntalBeställningar
FROM Beställningar
GROUP BY KundID;

-- Group by, räknar antal beställningar med kundens namn
SELECT Kunder.namn, COUNT(OrderID) AS AntalBeställningar
FROM Beställningar
INNER JOIN Kunder ON Beställningar.KundID = Kunder.KundID
GROUP BY Kunder.Namn;

SELECT Kunder.namn, COUNT(OrderID) AS AntalBeställningar
FROM Beställningar
INNER JOIN Kunder ON Beställningar.KundID = Kunder.KundID
GROUP BY Kunder.Namn
HAVING COUNT(OrderID) > 2; -- Ska vara mer än 2






-- Lektion 4: INDEX, TRIGGERS & CONSTRAINTS
-- INDEX – Skapa index på e-post i Kunder-tabellen
CREATE INDEX idx_email ON Kunder(Email);

-- För att se vårt index
SHOW INDEX FROM Kunder;

-- CONSTRAINTS – Säkerställa att pris alltid är större än 0, se om du kan hitta vilken rad det är

ALTER TABLE Produkter 
ADD CONSTRAINT check_pris CHECK (Pris > 0);

-- testa med en produkt som har pris 0
INSERT INTO Produkter (Namn, Pris, Kategori) 
VALUES ('Gratisprodukt', 0, 'Kläder');

-- Lägg till så vi får lagerstatur på våra produkter
ALTER TABLE Produkter ADD COLUMN Lagerstatus INT DEFAULT 10;

-- TRIGGER – Uppdatera lagersaldo efter en order
DELIMITER $$

CREATE TRIGGER uppdatera_lager
AFTER INSERT ON Orderrader
FOR EACH ROW
BEGIN
    UPDATE Produkter 
    SET Lagerstatus = Lagerstatus - NEW.Antal
    WHERE ProduktID = NEW.ProduktID;
END $$

DELIMITER ;

INSERT INTO Orderrader (OrderID, ProduktID, Antal, Pris) 
VALUES (1, 1, 2, 199.99);  -- Beställer 2 T-shirts

SELECT * FROM Produkter WHERE ProduktID = 1;

-- TRIGGER – Logga nya kunder i en logg-tabell
CREATE TABLE Kundlogg (
    LoggID INT AUTO_INCREMENT PRIMARY KEY,
    KundID INT,
    Registreringsdatum TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (KundID) REFERENCES Kunder(KundID)
);

DELIMITER $$

CREATE TRIGGER logga_ny_kund
AFTER INSERT ON Kunder
FOR EACH ROW
BEGIN
    INSERT INTO Kundlogg (KundID)
    VALUES (NEW.KundID);
END $$

DELIMITER ;

-- Testa om det fungerar med en ny kund
INSERT INTO Kunder (Namn, Email) VALUES ('Maria Karlsson', 'maria@email.com');
SELECT * FROM Kundlogg;


-- Lektion 5: JSON, NoSQL, Backup & Restore

-- Lagra JSON i MySQL
CREATE TABLE Produktinfo (
    ProduktID INT PRIMARY KEY,
    Info JSON NOT NULL
);

INSERT INTO Produktinfo (ProduktID, Info) VALUES
(1, '{ "namn": "T-shirt", "färg": "svart", "storlek": "M" }'),
(2, '{ "namn": "Jeans", "färg": "blå", "storlek": "L" }');

-- Backup av databasen, TERMINAL!
mysqldump -u root -p Klädbutik > kladbutik_backup.sql

-- Återställ databasen från backup
mysql -u root -p Klädbutik < kladbutik_backup.sql
