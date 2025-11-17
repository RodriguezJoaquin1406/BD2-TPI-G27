USE BD2_TPI_G27_CLINICA
GO

CREATE TRIGGER tr_cancelar_turno on Turno
INSTEAD OF DELETE
As
BEGIN
	DECLARE @IdCancelado TINYINT ;
	SELECT @IdCancelado = IdEstado 
	From EstadosTurnos 
	WHERE Detalle = 'Cancelado';

	IF @IdCancelado IS NOT NULL
	BEGIN
        UPDATE Turno
		SET IdEstadoTurno = @IdCancelado
		FROM Turno t
		INNER JOIN deleted d ON T.IdTurno = d.IdTurno
	END

	ELSE 
	BEGIN
		UPDATE Turno
		SET IdEstadoTurno = 3
		FROM Turno t
		INNER JOIN deleted d ON T.IdTurno = d.IdTurno
	END

	
END
go