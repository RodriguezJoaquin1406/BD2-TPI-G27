USE BD2_TPI_G27_CLINICA;
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

    -- --- DECLARACIÓN DE VARIABLES ---
    DECLARE @EstadoReservado TINYINT;
    DECLARE @IdTipoUsuarioLogueado TINYINT;
    DECLARE @IdPacienteLogueado INT;
    DECLARE @DuracionMinutos INT;
    DECLARE @CostoBase DECIMAL(10, 2);
    DECLARE @HoraFinCalculada TIME;

    -- --- VALIDACIONES DE REGLA DE NEGOCIO ---

    -- Validacion 1: Validar que el Paciente, Doctor y Procedimiento existan
    IF NOT EXISTS (SELECT 1 FROM UsuarioPaciente WHERE IdPaciente = @IdPacienteAAtender)
        BEGIN RETURN -1; END -- Error: Paciente no existe

    IF NOT EXISTS (SELECT 1 FROM Doctor WHERE IdDoctor = @IdDoctor)
        BEGIN RETURN -2; END -- Error: Doctor no existe
    
    IF NOT EXISTS (SELECT 1 FROM Procedimiento WHERE IdProcedimiento = @IdProcedimiento)
        BEGIN RETURN -3; END -- Error: Procedimiento no existe

    -- Validacion 2: Validar Permisos (Admin puede agendar para otros)
    SELECT @IdTipoUsuarioLogueado = IdTipoUsuario FROM CredencialesUsuarios WHERE IdUsuario = @IdUsuarioLogueado;
    SELECT @IdPacienteLogueado = IdPaciente FROM UsuarioPaciente WHERE IdUsuario = @IdUsuarioLogueado;

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
    
    -- VALIDACIÓN 6: Validar Especialidad del Doctor vs. Procedimiento
    IF NOT EXISTS (
        SELECT 1
        FROM ProcedimientoxEspecialidad pe
        INNER JOIN DoctorxEspecialidad de ON pe.IdEspecialidad = de.IdEspecialidad
        WHERE pe.IdProcedimiento = @IdProcedimiento
          AND de.IdDoctor = @IdDoctor
    )
    BEGIN
        RETURN -7; -- Error: El doctor no tiene la especialidad requerida.
    END

    -- --- FIN DE VALIDACIONES ---

    -- Si pasa todas las validaciones, procedemos a ESCRIBIR en la BD.
    -- Envolvemos todas las escrituras en una Transacción.

    BEGIN TRY
        -- 1. Inicia la "zona segura" de la transacción
        BEGIN TRANSACTION;

        -- Obtenemos el ID del estado 'Reservado'
        SELECT @EstadoReservado = IdEstado 
        FROM EstadosTurnos 
        WHERE Detalle = 'Reservado';

        -- 2. Ejecutamos la acción de INSERCIÓN
        INSERT INTO Turno (
            IdProcedimiento, IdDoctor, IdPaciente, IdEstadoTurno, 
            FechaTurno, HoraInicio, HoraFin, Monto
        )
        VALUES (
            @IdProcedimiento, @IdDoctor, @IdPacienteAAtender, @EstadoReservado,
            @FechaTurno, @HoraInicio, @HoraFinCalculada, @CostoBase
        );
        
        -- (Si tuvieras que hacer un segundo INSERT o un UPDATE, iría aquí)

        -- 3. Si todo lo anterior funcionó sin errores, guardamos permanentemente.
        COMMIT TRANSACTION;
        RETURN 1; -- Éxito

    END TRY
    BEGIN CATCH
        -- 4. Si ALGO dentro del bloque TRY falló (el INSERT, el COMMIT, etc.)
        -- SQL Server salta automáticamente aquí.

        -- Comprobamos si la transacción quedó "abierta"
        IF @@TRANCOUNT > 0
        BEGIN
            -- Deshacemos todo. El INSERT en Turno NUNCA se guardará.
            ROLLBACK TRANSACTION;
        END
        
        RETURN -99; -- Devuelve un error genérico de "Algo salió mal"
    END CATCH
END;
GO