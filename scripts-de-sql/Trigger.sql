USE BD2_TPI_G27_CLINICA
GO

--- TRIGGER 1

CREATE TRIGGER tr_cancelar_turno on Turno
INSTEAD OF DELETE
As
BEGIN
	
    DECLARE @IdCancelado TINYINT ;

	SELECT @IdCancelado = IdEstado 
	From EstadosTurnos 
	WHERE Detalle = 'Cancelado';

    UPDATE Turno
	SET IdEstadoTurno = ISNULL( @IdCancelado, 3)
	FROM Turno t
	INNER JOIN deleted d ON T.IdTurno = d.IdTurno
		
	
END
go

--- TRIGGER 2

CREATE TRIGGER tr_baja_paciente ON UsuarioPaciente
INSTEAD OF DELETE AS
BEGIN

	BEGIN TRY
    
	    IF (SELECT COUNT(*) FROM deleted) > 1
            BEGIN
                RAISERROR('Error: Este trigger solo permite dar de baja a un paciente a la vez.', 16, 1);
                ROLLBACK TRANSACTION; 
                RETURN;
        END
-- Despues del borrado de un paciente cancelar automaticamente sus turnos

		BEGIN TRAN;

		DECLARE @IdPacienteBorrar INT;
		DECLARE @IdUsuarioBorrar INT;
		
		SELECT 
			@IdPacienteBorrar = IdPaciente, 
			@IdUsuarioBorrar = IdUsuario
		FROM deleted;

		-- Obtener id de estado cancelado

		DECLARE @IdCancelado TINYINT ;
		SELECT @IdCancelado = IdEstado 
		From EstadosTurnos 
		WHERE Detalle = 'Cancelado';

		SET @IdCancelado = ISNULL(@IdCancelado, 3);

		UPDATE Turno 
		SET IdEstadoTurno = @IdCancelado
		WHERE
			IdPaciente = @IdPacienteBorrar AND
			FechaTurno >= CAST(GETDATE() AS DATE) AND
			IdEstadoTurno IN (1,2)
			
		-- IdEstadoTurno IN (1,2) 1 y 2 son reservado o confirmado

		DELETE FROM SolicitudesCambioTurno
		WHERE
			IdPaciente = @IdPacienteBorrar AND
			Aprobado = 0;

		-- Error mio, no hice una columna para un borrado logico
		-- Ia me recomendó hacer cambio de contraseña 

		UPDATE CredencialesUsuarios
		SET Contrasena = 'USER_DELETED' 
		WHERE IdUsuario = @IdUsuarioBorrar
		COMMIT TRAN;
	END TRY

	BEGIN CATCH
		ROLLBACK TRAN;
		THROW;
	END CATCH

END;
GO


USE BD2_TPI_G27_CLINICA;
GO

CREATE TRIGGER tr_baja_doctor
ON Doctor
INSTEAD OF DELETE
AS
BEGIN

    BEGIN TRY

        IF (SELECT COUNT(*) FROM deleted) > 1
        BEGIN
            RAISERROR('Error: Este trigger solo permite dar de baja a un doctor a la vez.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        BEGIN TRANSACTION;

        DECLARE @IdDoctorBorrar INT;
        DECLARE @IdUsuarioBorrar INT;

        SELECT 
            @IdDoctorBorrar = IdDoctor,
            @IdUsuarioBorrar = IdUsuario 
        FROM deleted;

        DECLARE @IdCancelado TINYINT;
        SELECT @IdCancelado = IdEstado 
        FROM EstadosTurnos 
        WHERE Detalle = 'Cancelado';

        SET @IdCancelado = ISNULL(@IdCancelado, 3);

        UPDATE Turno 
        SET IdEstadoTurno = @IdCancelado
        WHERE
            IdDoctor = @IdDoctorBorrar AND 
            FechaTurno >= CAST(GETDATE() AS DATE) AND
            IdEstadoTurno IN (1, 2); 

        DELETE FROM SolicitudesCambioTurno
        WHERE 
            IdTurno IN (
                SELECT IdTurno 
                FROM Turno 
                WHERE IdDoctor = @IdDoctorBorrar
            ) 
            AND Aprobado = 0;

        UPDATE CredencialesUsuarios
        SET Contrasena = 'DOC_DELETED_' + CAST(NEWID() AS VARCHAR(50))
        WHERE IdUsuario = @IdUsuarioBorrar;


        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO