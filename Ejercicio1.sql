CREATE DATABASE COMERCIAL
GO

USE COMERCIAL;
GO

CREATE TABLE Agencia
(
    CodAgencia SMALLINT PRIMARY KEY,
    DesAgencia VARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE AgenciaDeposito
(
    CodAgencia SMALLINT,
    CodDeposito SMALLINT,
    DesDeposito VARCHAR(50) NOT NULL,

    CONSTRAINT PK_AgenciaDeposito PRIMARY KEY (CodAgencia, CodDeposito),
    CONSTRAINT FK_AgenciaDeposito_CodAgencia FOREIGN KEY (CodAgencia) REFERENCES Agencia(CodAgencia)
);
GO

CREATE TABLE Transferencia
(
    NroTransferencia INT PRIMARY KEY IDENTITY (1,1),
    NroNotaEnvio INT,
    CodAgenciaSalida SMALLINT NOT NULL,
    CodDepositoSalida SMALLINT NOT NULL,
    CodAgenciaEntrada SMALLINT NOT NULL,
    CodDepositoEntrada SMALLINT NOT NULL,
    FechaTransferencia DATETIME NOT NULL,
    EstadoSalida BIT,
    EstadoEntrada BIT,

    CONSTRAINT FK_Transferencia_CodAgenciaSalida FOREIGN KEY (CodAgenciaSalida, CodDepositoSalida) REFERENCES AgenciaDeposito(CodAgencia, CodDeposito),
    CONSTRAINT FK_Transferencia_CodAgenciaEntrada FOREIGN KEY (CodAgenciaEntrada, CodDepositoEntrada) REFERENCES AgenciaDeposito(CodAgencia, CodDeposito),
    CONSTRAINT CHK_Transferencia_EstadoSalida CHECK (EstadoSalida IN (0,1)),
    CONSTRAINT CHK_Transferencia_EstadoEntrada CHECK (EstadoEntrada IN (0,1))
);
GO

CREATE TABLE Marca
(
    CodMarca SMALLINT PRIMARY KEY,
    DesMarca VARCHAR(40) NOT NULL UNIQUE
);
GO

CREATE TABLE Linea
(
    CodLinea SMALLINT PRIMARY KEY,
    DesLinea VARCHAR(40) NOT NULL UNIQUE
);
GO

CREATE TABLE Pais 
(
    CodPais SMALLINT PRIMARY KEY,
    DesPais VARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE Proveedor
(
    CodProveedor INT PRIMARY KEY,
    RazonSocial VARCHAR(50) NOT NULL UNIQUE,
    RUC VARCHAR(15) NOT NULL UNIQUE,
    Telefono VARCHAR(15),
    Fax VARCHAR(15),
    Email VARCHAR(50),
    CodPais SMALLINT NOT NULL,

    CONSTRAINT FK_Proveedor_CodPais FOREIGN KEY (CodPais) REFERENCES Pais(CodPais)
);
GO

CREATE TABLE Regimen
(
    CodRegimen INT PRIMARY KEY,
    DesRegimen VARCHAR(30) NOT NULL UNIQUE,
    PorcentajeIVA REAL NOT NULL,
);
GO

CREATE TABLE Articulo
(
    NroArticulo INT PRIMARY KEY,
    DesArticulo VARCHAR(50) NOT NULL UNIQUE,
    CodigoBarra VARCHAR(15) NOT NULL UNIQUE,
    CodMarca SMALLINT NOT NULL,
    CodLinea SMALLINT NOT NULL,
    CodProveedor INT NOT NULL,
    CodRegimen INT NOT NULL,
    Peso REAL NOT NULL,
    Volumen REAL NOT NULL,
    CostoDolares REAL NOT NULL,
    CostoGuaranies REAL NOT NULL,
    PrecioDolares MONEY NOT NULL,
    Estado BIT,

    CONSTRAINT FK_Articulo_CodMarca FOREIGN KEY (CodMarca) REFERENCES Marca(CodMarca),
    CONSTRAINT FK_Articulo_CodLinea FOREIGN KEY (CodLinea) REFERENCES Linea(CodLinea),
    CONSTRAINT FK_Articulo_CodProveedor FOREIGN KEY (CodProveedor) REFERENCES Proveedor(CodProveedor),
    CONSTRAINT FK_Articulo_CodRegimen FOREIGN KEY (CodRegimen) REFERENCES Regimen(CodRegimen),

    CONSTRAINT CHK_Articulo_Estado CHECK (Estado IN (0,1)),
);
GO

CREATE TABLE Lote
(
    NroLote INT PRIMARY KEY,
    NroArticulo INT NOT NULL,
    CodProveedor INT NOT NULL,
    FechaFabricacion DATE NOT NULL,
    FechaVencimiento DATE NOT NULL,
    ReferenciaProveedor VARCHAR(255) NOT NULL,

    CONSTRAINT FK_Lote_NroArticulo FOREIGN KEY (NroArticulo) REFERENCES Articulo(NroArticulo),
    CONSTRAINT FK_Lote_CodProveedor FOREIGN KEY (CodProveedor) REFERENCES Proveedor(CodProveedor)
);
GO

CREATE TABLE DetalleTransferencia
(
    NroTransferencia INT,
    CodAgencia SMALLINT,
    CodDeposito SMALLINT,
    NroArticulo INT,
    NroLote INT,
    CostoDoloares REAL,
    CostoGuaranies REAL,
    Cantidad FLOAT NOT NULL,

    CONSTRAINT PK_DetalleTransferencia_NroTransferencia PRIMARY KEY (NroTransferencia, CodAgencia, CodDeposito, NroArticulo, NroLote),
    CONSTRAINT FK_Transferencia_NroTransferencia FOREIGN KEY (NroTransferencia) REFERENCES Transferencia(NroTransferencia),
    CONSTRAINT FK_Transferencia_CodAgencia FOREIGN KEY (CodAgencia) REFERENCES Agencia(CodAgencia)
);
GO

CREATE TABLE Stock
(
    CodAgencia SMALLINT,
    CodDeposito SMALLINT,
    NroArticulo INT,
    NroLote INT,
    TotalCompras FLOAT NOT NULL DEFAULT 0,
    TotalVentas FLOAT NOT NULL DEFAULT 0,
    TotalDevoluciones FLOAT NOT NULL DEFAULT 0,
    TotalTransferenciasSalida FLOAT NOT NULL DEFAULT 0,
    TotalTransferenciasEntrada FLOAT NOT NULL DEFAULT 0,
    TotalAjustesPositivos FLOAT NOT NULL DEFAULT 0,
    TotalAjustesNegativos FLOAT NOT NULL DEFAULT 0,
    Existencia FLOAT NOT NULL DEFAULT 0,
    Estado BIT,

    CONSTRAINT PK_Stock PRIMARY KEY (CodAgencia,CodDeposito,NroArticulo,NroLote),

    CONSTRAINT FK_Stock_CodAgencia FOREIGN KEY (CodAgencia) REFERENCES Agencia(CodAgencia),
    CONSTRAINT FK_Stock_NroArticulo FOREIGN KEY (NroArticulo) REFERENCES Articulo(NroArticulo),
    CONSTRAINT FK_Stock_NroLote FOREIGN KEY (NroLote) REFERENCES Lote(NroLote),

    CONSTRAINT CHK_Stock_Estado CHECK (Estado IN (0,1)),
    CONSTRAINT CHK_Stock_TotalMayor CHECK (TotalCompras >= 0 AND TotalDevoluciones >= 0 AND TotalTransferenciasEntrada >= 0 AND TotalAjustesPositivos >= 0 AND Existencia >= 0),
    CONSTRAINT CHK_Stock_TotalMenor CHECK (TotalVentas >= 0 AND TotalTransferenciasSalida >= 0 AND TotalAjustesNegativos <= 0),

);
GO

CREATE PROCEDURE triggerTransaccionEliminado
AS
BEGIN
   BEGIN TRY
      BEGIN TRANSACTION
        UPDATE S
        SET 
            S.Existencia = S.Existencia - D.Cantidad,
            S.TotalTransferenciasEntrada = S.TotalTransferenciasEntrada - D.Cantidad
        FROM Stock S
        INNER JOIN DetalleTransferencia D 
            ON S.CodAgencia = D.CodAgencia
           AND S.CodDeposito = D.CodDeposito
           AND S.NroArticulo = D.NroArticulo
           AND S.NroLote = D.NroLote
        INNER JOIN Transferencia T 
            ON D.NroTransferencia = T.NroTransferencia
        WHERE T.EstadoSalida = 0 AND T.EstadoEntrada = 0
          AND D.CodAgencia = T.CodAgenciaEntrada
          AND D.CodDeposito = T.CodDepositoEntrada;

        UPDATE S
        SET 
            S.Existencia = S.Existencia + D.Cantidad,
            S.TotalTransferenciasSalida = S.TotalTransferenciasSalida - D.Cantidad
        FROM Stock S
        INNER JOIN DetalleTransferencia D 
            ON S.CodAgencia = D.CodAgencia
           AND S.CodDeposito = D.CodDeposito
           AND S.NroArticulo = D.NroArticulo
           AND S.NroLote = D.NroLote
        INNER JOIN Transferencia T 
            ON D.NroTransferencia = T.NroTransferencia
        WHERE T.EstadoSalida = 0 AND T.EstadoEntrada = 0
          AND D.CodAgencia = T.CodAgenciaSalida
          AND D.CodDeposito = T.CodDepositoSalida;

        DELETE D
        FROM DetalleTransferencia D
        INNER JOIN Transferencia T
            ON D.NroTransferencia = T.NroTransferencia
        WHERE T.EstadoSalida = 0 AND T.EstadoEntrada = 0;

        DELETE FROM Transferencia
        WHERE EstadoSalida = 0 AND EstadoEntrada = 0;

      COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT 'Error al eliminar transferencias abiertas.';
        PRINT ERROR_MESSAGE();
   END CATCH
END
GO