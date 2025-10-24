USE COMERCIAL;
GO

CREATE TABLE Compra
(
    NroCompra INT IDENTITY(1,1),
    CodProveedor INT NOT NULL,
    NroFacturaProveedor INT,
    CodAgencia SMALLINT NOT NULL,
    CodDeposito SMALLINT NOT NULL,
    CodMoneda SMALLINT NOT NULL,
    FechaCotizacion DATETIME NOT NULL,
    MontoCambio MONEY NOT NULL,
    FechaPedido DATETIME NOT NULL,
    FechaRecepcion DATETIME,
    Plazo INT NOT NULL,
    EstadoPedido CHAR(1) NOT NULL,
    MontoCostoDolares MONEY,
    MontoCostoGuaranies MONEY,
    Estado BIT,

    CONSTRAINT PK_Compra PRIMARY KEY (NroCompra, CodDeposito),
    CONSTRAINT FK_Compra_CodProveedor FOREIGN KEY (CodProveedor) REFERENCES Proveedor(CodProveedor),
    CONSTRAINT FK_Compra_CodAgencia FOREIGN KEY (CodAgencia) REFERENCES Agencia(CodAgencia),
    CONSTRAINT FK_Compra_CodMoneda FOREIGN KEY (CodMoneda) REFERENCES Moneda(CodMoneda),

    CONSTRAINT CHK_Compra_EstadoPedido CHECK (EstadoPedido IN ('A','C')),
    CONSTRAINT CHK_Compra_Estado CHECK (Estado IN (0,1))
);

CREATE TABLE DetalleCompra
(
    NroCompra INT,
    CodAgencia SMALLINT,
    CodDeposito SMALLINT,
    NroArticulo INT,
    NroLote INT,
    CostoDolaresAnterior REAL,
    CostoGuaraniesAnterior REAL,
    CostoDolares REAL,
    CostoGuaranies REAL,
    CodRegimen INT,
    Cantidad FLOAT NOT NULL,
    MontoCostoDolares MONEY,
    MontoCostoGuaranies MONEY,

    CONSTRAINT PK_DetalleCompra PRIMARY KEY (NroCompra,CodAgencia,CodDeposito,NroArticulo,NroLote),
    CONSTRAINT FK_DetalleCompra_NroCompra FOREIGN KEY (NroCompra,CodDeposito) REFERENCES Compra(NroCompra,CodDeposito),
    CONSTRAINT FK_DetalleCompra_CodAgencia FOREIGN KEY (CodAgencia) REFERENCES Agencia(CodAgencia)
);

CREATE TABLE DetalleFactura
(   
    NroFactura INT,
    CodAgencia SMALLINT,
    CodDeposito SMALLINT,
    NroArticulo INT,
    NroLote INT,
    CostoDolares REAL,
    CostoGuaranies REAL,
    PrecioDolares MONEY NOT NULL,
    PrecioNeto MONEY,
    CodRegimen INT,
    PorcentajeIVA REAL,
    Cantidad FLOAT NOT NULL,
    MontoTotal MONEY,
    MontoIVA MONEY,
    MontoNetoIVA MONEY,

    CONSTRAINT PK_DetalleFactura PRIMARY KEY (NroFactura,CodAgencia,CodDeposito,NroArticulo,NroLote),
    CONSTRAINT FK_DetalleFactura_NroFactura FOREIGN KEY (NroFactura, CodDeposito) REFERENCES Factura(NroFactura, CodDeposito),
    CONSTRAINT FK_DetalleFactura_CodAgencia FOREIGN KEY (CodAgencia) REFERENCES Agencia(CodAgencia),
    CONSTRAINT FK_DetalleFactura_CodRegimen FOREIGN KEY (CodRegimen) REFERENCES Regimen(CodRegimen)
);
GO

CREATE PROCEDURE gestionComprasPorFecha
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
            SELECT
                A.NroArticulo,
                A.DesArticulo,
                A.CodigoBarra,
                A.CodMarca,
                A.CodLinea,
                A.CodProveedor,
                A.CodRegimen,
                A.Peso,
                A.Volumen,
                A.CostoDolares,
                A.CostoGuaranies,
                A.PrecioDolares,
                A.Estado BIT,
                P.CodProveedor,
                P.RazonSocial
            FROM
                Articulo A
                INNER JOIN Proveedor P ON A.CodProveedor = P.CodProveedor
                INNER JOIN Marca M ON A.CodMarca = M.CodMarca
                INNER JOIN Linea L ON A.CodLinea = L.CodLinea
            WHERE
                EXISTS (
                SELECT 1
                FROM DetalleCompra DC
                INNER JOIN Compra C ON DC.NroCompra = C.NroCompra
                WHERE 
                    DC.NroArticulo = A.NroArticulo
                    AND C.FechaPedido >= '20220101' AND C.FechaPedido < '20220101'
                    AND C.Estado = 1
                )
                AND NOT EXISTS (
                    SELECT 1
                    FROM DetalleCompra DC
                    INNER JOIN Compra C ON DC.NroCompra = C.NroCompra
                    WHERE 
                        DC.NroArticulo = A.NroArticulo
                        
                        AND C.Estado = 1
                )
                AND NOT EXISTS (
                SELECT 1
                FROM DetalleFactura DF
                INNER JOIN Factura F ON DF.NroFactura = F.NroFactura
                WHERE 
                    DF.NroArticulo = A.NroArticulo
                    AND F.FechaEmision >= '20220101'
                    AND F.Estado = 1
            )
        ORDER BY 
            A.CodProveedor, 
            A.CodLinea;
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT 'Error al eliminar transferencias abiertas.';
        PRINT ERROR_MESSAGE();
   END CATCH
END
GO