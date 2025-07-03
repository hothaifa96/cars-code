-- Create the cars table
CREATE TABLE cars (
    id INT AUTO_INCREMENT PRIMARY KEY,
    make VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    color VARCHAR(30) NOT NULL
);

-- Insert 6 sample cars
INSERT INTO cars (make, year, color) VALUES
('Toyota', 2020, 'Red'),
('Honda', 2018, 'Blue'),
('Ford', 2019, 'Black'),
('Chevrolet', 2021, 'White'),
('BMW', 2017, 'Silver'),
('Tesla', 2022, 'Green');