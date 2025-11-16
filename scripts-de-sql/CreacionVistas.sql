USE BD2_TPI_G27_CLINICA
go


----------------------------------------------------
-- Vista Numero 1: ---------------------------------
-- Turnos de la última semana para la clínica ------
----------------------------------------------------

CREATE VIEW vwTurnosUltimaSemana AS
SELECT
    t.IdTurno,
    t.FechaTurno,
    t.HoraInicio,
    t.HoraFin,
    t.Monto,
    t.FechaCreacion,
    p.NombreProcedimiento,
    d.IdDoctor,
    cuDoc.Nombre + ' ' + cuDoc.Apellido AS Doctor,
    up.IdPaciente,  
    cuPat.Nombre + ' ' + cuPat.Apellido AS Paciente,
    et.Detalle AS EstadoTurno
FROM 
    Turno t
INNER JOIN 
    Procedimiento p ON t.IdProcedimiento = p.IdProcedimiento
INNER JOIN 
    Doctor d ON t.IdDoctor = d.IdDoctor
INNER JOIN 
    CredencialesUsuarios cuDoc ON d.IdUsuario = cuDoc.IdUsuario
INNER JOIN 
    UsuarioPaciente up     ON t.IdPaciente = up.IdPaciente
INNER JOIN 
    CredencialesUsuarios cuPat ON up.IdUsuario = cuPat.IdUsuario
INNER JOIN 
    EstadosTurnos et       ON t.IdEstadoTurno = et.IdEstado
WHERE t.FechaTurno >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
GO

-- Ejemplo de uso:

SELECT * FROM vwTurnosUltimaSemana
ORDER BY FechaTurno DESC, HoraInicio ASC;

----------------------------------------------------
-- Vista Numero 2: ---------------------------------
-- Turnos para el dia de hoy -----------------------
----------------------------------------------------

CREATE VIEW vwTurnosParaHoy AS
SELECT
    t.IdTurno,
    t.FechaTurno,
    t.HoraInicio,
    t.HoraFin,
    t.Monto,
    et.Detalle AS EstadoTurno,
    p.NombreProcedimiento,
    d.IdDoctor,
    cuDoc.Nombre + ' ' + cuDoc.Apellido AS Doctor,
    up.IdPaciente,
    cuPat.Nombre + ' ' + cuPat.Apellido AS Paciente
FROM 
    Turno t
INNER JOIN 
    Procedimiento p ON t.IdProcedimiento = p.IdProcedimiento
INNER JOIN 
    Doctor d ON t.IdDoctor = d.IdDoctor
INNER JOIN 
    CredencialesUsuarios cuDoc ON d.IdUsuario = cuDoc.IdUsuario
INNER JOIN 
    UsuarioPaciente up ON t.IdPaciente = up.IdPaciente
INNER JOIN 
    CredencialesUsuarios cuPat ON up.IdUsuario = cuPat.IdUsuario
INNER JOIN 
    EstadosTurnos et ON t.IdEstadoTurno = et.IdEstado
WHERE 
    t.FechaTurno = CAST(GETDATE() AS DATE) 
GO

-- Ejemplo de uso:

SELECT * FROM vwTurnosParaHoy
ORDER BY HoraInicio ASC;


----------------------------------------------------
-- Vista Numero 3: ---------------------------------
-- Reporte Facturacion por Doctor ------------------
----------------------------------------------------

USE BD2_TPI_G27_CLINICA;
GO

CREATE VIEW vwReporteFacturacionPorDoctor AS
SELECT
    d.IdDoctor,
    cu.Nombre + ' ' + cu.Apellido AS Doctor,
    
    COUNT(t.IdTurno) AS CantidadTurnosAsistidos,
    
    SUM(t.Monto) AS TotalFacturado
FROM 
    Turno t
INNER JOIN 
    EstadosTurnos et ON t.IdEstadoTurno = et.IdEstado
INNER JOIN 
    Doctor d ON t.IdDoctor = d.IdDoctor
INNER JOIN 
    CredencialesUsuarios cu ON d.IdUsuario = cu.IdUsuario
WHERE
    et.Detalle = 'Asistido'
GROUP BY
    d.IdDoctor, cu.Nombre, cu.Apellido
GO


-- Ejmplo uso: Todos los doctores

SELECT * FROM vwReporteFacturacionPorDoctor;


---
-- vista nro 4

CREATE VIEW vwSolicitudesDeCambioPendientes AS
SELECT
    sct.IdSolicitud,
    sct.IdTurno,
    
    -- Información del Paciente
    cu_pac.Nombre + ' ' + cu_pac.Apellido AS NombrePaciente,
    
    -- Información del Turno Original
    t.FechaTurno AS FechaOriginal,
    t.HoraInicio AS HoraOriginal,
    cu_doc.Nombre + ' ' + cu_doc.Apellido AS NombreDoctor,
    
    -- Información de la Nueva Solicitud
    sct.FechaTurnoNueva AS FechaSolicitada,
    sct.HoraInicioNueva AS HoraSolicitada,
    sct.FechaSolicitudCambio AS FechaDeLaSolicitud
FROM
    SolicitudesCambioTurno sct
INNER JOIN
    Turno t ON sct.IdTurno = t.IdTurno
INNER JOIN
    UsuarioPaciente up ON t.IdPaciente = up.IdPaciente
INNER JOIN
    CredencialesUsuarios cu_pac ON up.IdUsuario = cu_pac.IdUsuario
INNER JOIN
    Doctor d ON t.IdDoctor = d.IdDoctor
INNER JOIN
    CredencialesUsuarios cu_doc ON d.IdUsuario = cu_doc.IdUsuario
WHERE
    sct.Aprobado = 0 -- Filtra solo las que están PENDIENTES
GO