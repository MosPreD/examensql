USE COMERCIAL;
GO

CREATE TABLE Cobrador
(
    CodCobrador SMALLINT PRIMARY KEY,
    NombreCobrador VARCHAR(50) NOT NULL,
    PorcComision REAL NOT NULL

);

CREATE TABLE Zona
(
    CodZona SMALLINT PRIMARY KEY,
    DesZona VARCHAR(50) NOT NULL UNIQUE

);

CREATE TABLE Ramo
(
    CodRamo SMALLINT PRIMARY KEY,
    DesRamo VARCHAR(50) NOT NULL UNIQUE

);

CREATE TABLE Vendedor
(
    CodVendedor SMALLINT PRIMARY KEY,
    NombreVendedor VARCHAR(50) NOT NULL,
    PorcComision REAL NOT NULL,
    Estado BIT,

    CONSTRAINT CHK_Vendedor_Estado CHECK (Estado IN (0,1))
);

CREATE TABLE Cuenta
(
    NroCuenta INT PRIMARY KEY,
    NombreCuenta VARCHAR(50) NOT NULL,
    RazonSocial VARCHAR(50) NOT NULL,
    RUC VARCHAR(15) NOT NULL,
    Telefono VARCHAR(15),
    CodVendedor SMALLINT NOT NULL,
    CodRamo SMALLINT NOT NULL,
    CodZona SMALLINT NOT NULL,
    CodCobrador SMALLINT NOT NULL,
    TotalDebitosGs MONEY NOT NULL DEFAULT 0,
    TotalCreditosGs MONEY NOT NULL DEFAULT 0,
    TotalDebitosDl MONEY NOT NULL DEFAULT 0,
    TotalCreditosDl MONEY NOT NULL DEFAULT 0,
    LimiteCreditoDL MONEY NOT NULL DEFAULT 0,
    LimiteCreditoGS MONEY NOT NULL DEFAULT 0,
    Estado BIT,

    CONSTRAINT FK_Cuenta_CodVendedor FOREIGN KEY (CodVendedor) REFERENCES Vendedor(CodVendedor),
    CONSTRAINT FK_Cuenta_CodRamo FOREIGN KEY (CodRamo) REFERENCES Ramo(CodRamo),
    CONSTRAINT FK_Cuenta_CodZona FOREIGN KEY (CodZona) REFERENCES Zona(CodZona),
    CONSTRAINT FK_Cuenta_CodCobrador FOREIGN KEY (CodCobrador) REFERENCES Cobrador(CodCobrador),
    
    CONSTRAINT CHK_Cuenta_Estado CHECK (Estado IN (0,1))
);

CREATE TABLE Moneda
(
    CodMoneda SMALLINT PRIMARY KEY,
    DesMoneda VARCHAR(50) NOT NULL UNIQUE
);  

CREATE TABLE Factura
(
    NroFactura INT IDENTITY(1,1),
    NroCuenta INT NOT NULL,
    CodVendedor SMALLINT NOT NULL,
    PorcComision REAL NOT NULL,
    CodAgencia SMALLINT NOT NULL,
    CodDeposito SMALLINT NOT NULL,
    CodMoneda SMALLINT NOT NULL,
    FechaCotizacion DATETIME NOT NULL,
    MontoCambio MONEY NOT NULL,
    FechaEmision DATETIME,
    FechaRendicion DATETIME,
    Plazo INT NOT NULL,
    PorcDescuento REAL NOT NULL DEFAULT 0,
    MontoTotal MONEY,
    MontoIVA MONEY,
    MontoNetoIVA MONEY,
    Estado BIT,

    CONSTRAINT PK_Factura PRIMARY KEY (NroFactura,CodDeposito),
    CONSTRAINT FK_Factura_NroCuenta FOREIGN KEY (NroCuenta) REFERENCES Cuenta(NroCuenta),
    CONSTRAINT FK_Factura_CodVendedor FOREIGN KEY (CodVendedor) REFERENCES Vendedor(CodVendedor),
    CONSTRAINT FK_Factura_CodAgencia FOREIGN KEY (CodAgencia) REFERENCES Agencia(CodAgencia),
    CONSTRAINT FK_Factura_CodMoneda FOREIGN KEY (CodMoneda) REFERENCES Moneda(CodMoneda),

    CONSTRAINT CHK_Factura_Estado CHECK (Estado IN (0,1))
);
GO

CREATE PROCEDURE gestionFactura
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
            SELECT 
                C.NroCuenta,
                C.NombreCuenta,
                C.RazonSocial,
                C.RUC,
                C.Telefono,
                V.NombreVendedor,
                R.DesRamo,
                Z.DesZona,
                SUM(F.MontoNetoIVA * F.MontoCambio) AS TotalFacturadoCuenta,
                CAST((SUM(F.MontoNetoIVA * F.MontoCambio) / 
                (SELECT SUM(F2.MontoNetoIVA * F2.MontoCambio)
                    FROM Factura F2
                    WHERE F2.Estado = 1 AND YEAR(F2.FechaEmision) = 2023)) * 100 AS DECIMAL(10,2)) AS PorcentajeParticipacion,
                (SELECT SUM(F3.MontoNetoIVA * F3.MontoCambio)
                 FROM Factura F3
                 WHERE F3.Estado = 1 AND YEAR(F3.FechaEmision) = 2023) AS ImporteTotalFacturado
            FROM 
                Factura F
                INNER JOIN Cuenta C ON F.NroCuenta = C.NroCuenta
                INNER JOIN Vendedor V ON C.CodVendedor = V.CodVendedor
                INNER JOIN Ramo R ON C.CodRamo = R.CodRamo
                INNER JOIN Zona Z ON C.CodZona = Z.CodZona
            WHERE 
                F.Estado = 1 AND YEAR(F.FechaEmision) = 2023
            GROUP BY 
                C.NroCuenta, C.NombreCuenta, C.RazonSocial, C.RUC, C.Telefono, V.NombreVendedor, R.DesRamo, Z.DesZona
            HAVING 
                (SUM(F.MontoNetoIVA * F.MontoCambio) / 
                    (SELECT SUM(F4.MontoNetoIVA * F4.MontoCambio)
                     FROM Factura F4
                     WHERE F4.Estado = 1
                        AND YEAR(F4.FechaEmision) = 2023)) * 100 > 5
            ORDER BY 
                PorcentajeParticipacion DESC;
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT 'Error al gestionar la factura.';
        PRINT ERROR_MESSAGE();
    END CATCH
END
GO