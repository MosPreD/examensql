USE COMERCIAL;
GO

CREATE PROCEDURE triggerDesplegarArticulos
AS
BEGIN
    BEGIN TRY
        SELECT 
            A.NroArticulo,
            A.DesArticulo,
            SUM(S.Existencia) AS TotalExistencia,
            SUM(CASE WHEN L.FechaVencimiento < GETDATE() THEN S.Existencia ELSE 0 END) AS ExistenciaVencida,
            SUM(CASE WHEN L.FechaVencimiento >= GETDATE() THEN S.Existencia ELSE 0 END) AS ExistenciaNoVencida,
            CASE 
                WHEN SUM(S.Existencia) = 0 THEN 0
                ELSE 
                    (SUM(CASE WHEN L.FechaVencimiento < GETDATE() THEN S.Existencia ELSE 0 END) * 100.0) / SUM(S.Existencia)
            END AS PorcentajeVencido
        FROM Articulo A
        INNER JOIN Stock S ON A.NroArticulo = S.NroArticulo
        INNER JOIN Lote L ON S.NroLote = L.NroLote
        GROUP BY A.NroArticulo, A.DesArticulo
        ORDER BY PorcentajeVencido DESC;
    END TRY

    BEGIN CATCH
        PRINT 'Error al mostrar los artículos:';
        PRINT ERROR_MESSAGE();
    END CATCH
END
GO