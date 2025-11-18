USE BD2_TPI_G27_CLINICA;
GO

-------------------------------------------------------------------------
--                   SCRIPT DE PRUEBA CORREGIDO
-- Este script ha sido ajustado para usar los IDs correctos de tu
-- script de carga de datos.
-------------------------------------------------------------------------

DECLARE @Resultado INT;

-- CASO 1: ÉXITO (Happy Path)
-- Intentamos agendar un turno válido.
-- El Admin (IdUsuario = 1) agenda para el paciente Santiago (IdPaciente = 5)
-- con el Dr. Carlos (IdDoctor = 1) un Electrocardiograma (IdProcedimiento = 1).
-- Horario: 2025-12-20 a las 11:00 (debería estar libre).

PRINT '>>> PRUEBA 1: Agendar Turno Válido';

EXEC @Resultado = sp_AgendarNuevoTurno
    @IdUsuarioLogueado = 1,      -- Admin (Usuario ID: 1)
    @IdPacienteAAtender = 5,     -- Paciente Santiago (Paciente ID: 5)
    @IdDoctor = 1,               -- Dr. Carlos (Doctor ID: 1, Especialidad: Cardiología)
    @IdProcedimiento = 1,        -- Electrocardiograma (Requiere Cardiología)
    @FechaTurno = '2025-12-20',
    @HoraInicio = '11:00:00';

-- Debería devolver 1 (Éxito) y mostrar el nuevo turno creado.
SELECT @Resultado AS [Resultado Caso 1 (Esperado: 1)];
SELECT * FROM Turno WHERE FechaTurno = '2025-12-20' AND HoraInicio = '11:00:00';
GO

-- CASO 2: ERROR DE SUPERPOSICIÓN (Colisión)
-- Intentamos agendar al mismo Dr. Carlos (IdDoctor = 1) a las 11:15.
-- Esto colisiona con el turno de 11:00 a 11:30 que acabamos de crear.

PRINT '>>> PRUEBA 2: Error de Superposición';
DECLARE @Resultado2 INT;

EXEC @Resultado2 = sp_AgendarNuevoTurno
    @IdUsuarioLogueado = 1,
    @IdPacienteAAtender = 6,     -- Paciente Laura (Paciente ID: 6)
    @IdDoctor = 1,               -- Mismo Doctor (Carlos)
    @IdProcedimiento = 1,        -- Electrocardiograma
    @FechaTurno = '2025-12-20',  -- Misma fecha
    @HoraInicio = '11:15:00';    -- ¡COLISIÓN con el turno de 11:00 a 11:30!

-- Debería devolver -6 (Error: Horario Ocupado)
SELECT @Resultado2 AS [Resultado Caso 2 (Esperado: -6)];
GO

-- CASO 3: ERROR DE ESPECIALIDAD
-- Intentamos que la Dra. Luisa (IdDoctor = 2, Dermatología) haga un
-- Electrocardiograma (IdProcedimiento = 1, Cardiología).

PRINT '>>> PRUEBA 3: Error de Especialidad';
DECLARE @Resultado3 INT;

EXEC @Resultado3 = sp_AgendarNuevoTurno
    @IdUsuarioLogueado = 1,
    @IdPacienteAAtender = 5,     -- Paciente Santiago (Paciente ID: 5)
    @IdDoctor = 2,               -- Dra. Luisa (Doctor ID: 2, Especialidad: Dermatología)
    @IdProcedimiento = 1,        -- Electrocardiograma (Requiere Cardiología)
    @FechaTurno = '2025-12-22',
    @HoraInicio = '09:00:00';

SELECT @Resultado3 AS [Resultado Caso 3 (Esperado: -7)];
GO

-- CASO 4: ERROR DE FECHA PASADA

PRINT '>>> PRUEBA 4: Fecha Pasada';
DECLARE @Resultado4 INT;

EXEC @Resultado4 = sp_AgendarNuevoTurno
    @IdUsuarioLogueado = 1,
    @IdPacienteAAtender = 5,
    @IdDoctor = 1,
    @IdProcedimiento = 1,
    @FechaTurno = '2020-01-01',  -- Fecha en el pasado
    @HoraInicio = '09:00:00';

-- Debería devolver -5 (Error: Fecha no válida)
SELECT @Resultado4 AS [Resultado Caso 4 (Esperado: -5)];
GO