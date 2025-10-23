USE COMERCIAL;
GO

CREATE TABLE Inventario
(
	NroInventario INT PRIMARY KEY,
	FechaInventario DATE NOT NULL,
	Estado BIT,

    CONSTRAINT CHK_Inventario_Estado CHECK (Estado IN (0,1)),
);
GO

CREATE TABLE Ajuste
(
    NroAjuste INT PRIMARY KEY IDENTITY (1,1),
    NroComprobante VARCHAR(15) NOT NULL,
    CodAgencia SMALLINT NOT NULL,
    CodDeposito SMALLINT NOT NULL,
    FechaAjuste DATETIME NOT NULL,
    Estado BIT,

    CONSTRAINT FK_Ajuste_CodAgencia FOREIGN KEY (CodAgencia, CodDeposito) REFERENCES AgenciaDeposito(CodAgencia, CodDeposito),
    CONSTRAINT CHK_Ajuste_Estado CHECK (Estado IN (0,1))
);
GO

CREATE TABLE DetalleInventario
(   
    NroInventario INT,
    CodAgencia SMALLINT,
    CodDeposito SMALLINT,
    NroArticulo INT,
    NroLote INT,
    NroConteo INT,
    TipoConteo CHAR(1) NOT NULL,
    CantidadCongelada FLOAT NOT NULL,
    MomentoExistenciaCongelada DATETIME,
    CantidadFisica FLOAT NOT NULL,
    NroAjuste INT,
    Estado BIT,

    CONSTRAINT PK_DetalleInventario PRIMARY KEY (NroInventario,CodAgencia,CodDeposito,NroArticulo,NroLote,NroConteo),
    
    CONSTRAINT FK_DetalleInventario_NroInventario FOREIGN KEY (NroInventario) REFERENCES Inventario(NroInventario),
    CONSTRAINT FK_DetalleInventario_CodAgencia FOREIGN KEY (CodAgencia) REFERENCES Agencia(CodAgencia),
    CONSTRAINT FK_DetalleInventario_NroAjuste FOREIGN KEY (NroAjuste) REFERENCES Ajuste(NroAjuste),

    CONSTRAINT CHK_DetalleInventario_TipoConteo CHECK (TipoConteo IN ('F','D','I')),
    CONSTRAINT CHK_DetalleInventario_Estado CHECK (Estado IN (0,1))
);
GO

CREATE PROCEDURE triggerInsercion
AS
BEGIN
   BEGIN TRY
      BEGIN TRANSACTION
        DECLARE @NroInventario INT;

        SET @NroInventario = SCOPE_IDENTITY();

        INSERT INTO Inventario (FechaInventario, Estado) VALUES (GETDATE(), 0);

        INSERT INTO DetalleInventario 
        (
            NroInventario,CodAgencia,CodDeposito,NroArticulo,NroLote,NroConteo,TipoConteo,CantidadCongelada,MomentoExistenciaCongelada,CantidadFisica,NroAjuste,Estado
        )
        SELECT
            @NroInventario,
            S.CodAgencia,
            S.CodDeposito,
            S.NroArticulo,
            S.NroLote,
            1,
            'I',
            S.Existencia,
            GETDATE(),
            0,
            NULL,
            0
        FROM Stock S
        WHERE S.CodAgencia = 0 AND S.CodDeposito = 25;
      COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
        ROLLBACK TRANSACTION
        PRINT 'Error al insertar.';
        PRINT ERROR_MESSAGE();
   END CATCH
END
GO