USE BD2_TPI_G27_CLINICA;
GO

DROP PROCEDURE IF EXISTS sp_CrearSolicitudDeCambio;
GO

CREATE PROCEDURE sp_CrearSolicitudDeCambio
    @IdTurno INT,
    @IdUsuarioLogueado INT,
    @FechaNueva DATE,
    @HoraNueva TIME
AS
BEGIN
    SET NOCOUNT ON;

    -- --- VALIDACIONES ---

    -- Validacion 1: El turno debe existir
    IF NOT EXISTS (SELECT 1 FROM Turno WHERE IdTurno = @IdTurno)
    BEGIN
        RETURN -1; -- Error: El turno no existe.
    END

    -- Validacion 2: El estado del turno permite un cambio.
    DECLARE @EstadoTurno TINYINT;
    SELECT @EstadoTurno = IdEstadoTurno FROM Turno WHERE IdTurno = @IdTurno;

    IF @EstadoTurno IN (2, 3, 4) -- Confirmado, Cancelado, Asistido
    BEGIN
        RETURN -2; -- Retorno -2 : El turno no puede pedir una solicitud de cambio.
    END

    -- Validacion 3: Validar permisos (Admin Override)
    DECLARE @IdTipoUsuarioLogueado TINYINT;
    SELECT @IdTipoUsuarioLogueado = IdTipoUsuario 
    FROM CredencialesUsuarios 
    WHERE IdUsuario = @IdUsuarioLogueado;

    DECLARE @IdPacienteOriginal INT;
    SELECT @IdPacienteOriginal = IdPaciente 
    FROM Turno 
    WHERE IdTurno = @IdTurno;

    DECLARE @IdPacienteLogueado INT;
    SELECT @IdPacienteLogueado = IdPaciente 
    FROM UsuarioPaciente 
    WHERE IdUsuario = @IdUsuarioLogueado;

    
    -- no es Admin Y TAMPOCO es el dueño del turno

    IF (@IdTipoUsuarioLogueado != 1 AND @IdPacienteOriginal != @IdPacienteLogueado)
    BEGIN
        RETURN -3; -- Retorna -3 : No tiene permisos.
    END

    -- Validacion 4: Validar que el turno no tenga una solicitud pendiente.
    IF EXISTS (SELECT 1 FROM SolicitudesCambioTurno WHERE IdTurno = @IdTurno AND Aprobado = 0)
    BEGIN
        RETURN -4; -- Retorno -4 : Ya hay una solicitud existente para este turno.
    END

    -- Validacion 5: Validar que la fecha solicitada no sea pasada.
    IF @FechaNueva < CAST(GETDATE() AS DATE)
    BEGIN
        RETURN -5; -- Retorno -5 : Eligio una fecha caducada.
    END

    -- Validacion 6: Validar superposición de horario
    DECLARE @IdDoctorDelTurno INT;
    DECLARE @DuracionMinutos INT;
    
    SELECT 
        @IdDoctorDelTurno = t.IdDoctor,
        @DuracionMinutos = p.DuracionMinutos
    FROM Turno t
    INNER JOIN Procedimiento p ON t.IdProcedimiento = p.IdProcedimiento
    WHERE t.IdTurno = @IdTurno;

    DECLARE @HoraFinNueva TIME = DATEADD(MINUTE, @DuracionMinutos, @HoraNueva);

    IF EXISTS (
        SELECT 1
        FROM Turno t
        WHERE t.IdDoctor = @IdDoctorDelTurno
          AND t.FechaTurno = @FechaNueva
          AND t.IdTurno != @IdTurno
          AND t.HoraInicio < @HoraFinNueva
          AND t.HoraFin > @HoraNueva
    )
    BEGIN
        RETURN -6; -- Retorno -6 : El nuevo horario no está disponible.
    END

    -- --- FIN DE VALIDACIONES ---

    INSERT INTO SolicitudesCambioTurno (IdTurno, IdPaciente, FechaTurnoNueva, HoraInicioNueva, Aprobado)
    VALUES (@IdTurno, @IdPacienteOriginal, @FechaNueva, @HoraNueva, DEFAULT);

    RETURN 1; -- Éxito
END;
GO


-- 2do stored procedure

USE BD2_TPI_G27_CLINICA;
GO

DROP PROCEDURE IF EXISTS sp_AgendarNuevoTurno;
GO

CREATE PROCEDURE sp_AgendarNuevoTurno
    @IdUsuarioLogueado INT,
    @IdPacienteAAtender INT,
    @IdDoctor INT,
    @IdProcedimiento INT,
    @FechaTurno DATE,
    @HoraInicio TIME
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- --- DECLARACIÓN DE VARIABLES ---
        DECLARE @EstadoReservado TINYINT;
        DECLARE @IdTipoUsuarioLogueado TINYINT;
        DECLARE @IdPacienteLogueado INT;
        DECLARE @DuracionMinutos INT;
        DECLARE @CostoBase DECIMAL(10, 2);
        DECLARE @HoraFinCalculada TIME;

        -- --- VALIDACIONES PRINCIPALES ---

        -- Validacion 1: Validar que el Paciente, Doctor y Procedimiento existan
        IF NOT EXISTS (SELECT 1 FROM UsuarioPaciente WHERE IdPaciente = @IdPacienteAAtender)
            BEGIN RETURN -1; END -- Error: Paciente no existe

        IF NOT EXISTS (SELECT 1 FROM Doctor WHERE IdDoctor = @IdDoctor)
            BEGIN RETURN -2; END -- Error: Doctor no existe
        
        IF NOT EXISTS (SELECT 1 FROM Procedimiento WHERE IdProcedimiento = @IdProcedimiento)
            BEGIN RETURN -3; END -- Error: Procedimiento no existe

        -- Validacion 2: Validar Permisos (Admin puede agendar para otros)
        SELECT @IdTipoUsuarioLogueado = IdTipoUsuario 
        FROM CredencialesUsuarios 
        WHERE IdUsuario = @IdUsuarioLogueado;

        SELECT @IdPacienteLogueado = IdPaciente 
        FROM UsuarioPaciente 
        WHERE IdUsuario = @IdUsuarioLogueado;

        IF (@IdTipoUsuarioLogueado != 1 AND @IdPacienteAAtender != @IdPacienteLogueado)
        BEGIN
            RETURN -4; -- Error: No tiene permisos para agendar turnos para otro paciente.
        END

        -- Validacion 3: Validar que la fecha no sea en el pasado
        IF @FechaTurno < CAST(GETDATE() AS DATE)
        BEGIN
            RETURN -5; -- Error: No se pueden agendar turnos en fechas pasadas.
        END

        -- Validacion 4: Obtener datos para cálculos (Costo y Duración)
        SELECT 
            @DuracionMinutos = DuracionMinutos,
            @CostoBase = CostoBase
        FROM Procedimiento 
        WHERE IdProcedimiento = @IdProcedimiento;

        -- Validacion 5: Validar Superposición de Horario
        SET @HoraFinCalculada = DATEADD(MINUTE, @DuracionMinutos, @HoraInicio);

        IF EXISTS (
            SELECT 1
            FROM Turno t
            WHERE t.IdDoctor = @IdDoctor
              AND t.FechaTurno = @FechaTurno
              AND t.HoraInicio < @HoraFinCalculada
              AND t.HoraFin > @HoraInicio
        )
        BEGIN
            RETURN -6; -- Error: El horario con ese doctor ya está ocupado.
        END
        
        -- VALIDACIÓN 6: Validar Especialidad Doctor vs. Procedimiento
        -- Esta consulta comprueba si existe al menos UNA especialidad en común
        -- entre las que el doctor TIENE y las que el procedimiento REQUIERE.

        IF NOT EXISTS (
            SELECT 1
            FROM ProcedimientoxEspecialidad pe
            INNER JOIN DoctorxEspecialidad de ON pe.IdEspecialidad = de.IdEspecialidad
            WHERE pe.IdProcedimiento = @IdProcedimiento
              AND de.IdDoctor = @IdDoctor
        )
        BEGIN
            -- Si la subconsulta no devuelve filas, no hay coincidencias.
            RETURN -7; -- Error: El doctor seleccionado no tiene la especialidad requerida para este procedimiento.
        END

        -- --- FIN DE VALIDACIONES ---

        -- Si pasa todas las validaciones, preparamos la inserción
        
        -- Obtener el ID del estado 'Reservado' (es el 1 en tu script)
        SELECT @EstadoReservado = IdEstado 
        FROM EstadosTurnos 
        WHERE Detalle = 'Reservado';

        -- --- INSERCIÓN ---
        INSERT INTO Turno (
            IdProcedimiento, IdDoctor, IdPaciente, IdEstadoTurno, 
            FechaTurno, HoraInicio, HoraFin, Monto
        )
        VALUES (
            @IdProcedimiento, @IdDoctor, @IdPacienteAAtender, @EstadoReservado,
            @FechaTurno, @HoraInicio, @HoraFinCalculada, @CostoBase
        );

        RETURN 1; -- Éxito

    END TRY
    BEGIN CATCH
        
        RETURN -99;
    END CATCH
END;
GO