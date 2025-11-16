-- Script de carga de datos

USE BD2_TPI_G27_CLINICA
GO

-- Tipos de usuarios
INSERT INTO TiposUsuarios (Descripcion) VALUES
('Administrador'), ('Doctor'), ('Paciente');

-- Estados de Turnos
INSERT INTO EstadosTurnos (Detalle) VALUES
('Reservado'), ('Confirmado'), ('Cancelado'), ('Asistido'), ('Ausente');
-- Primero se reserva el turno y luego el cliente confirma.
-- reservado = pago seña (PUEDE PEDIR CAMBIO)
-- confirmado = ya se confirmo fecha y no se da lugar a modificacion de fecha (NO PUEDE PEDIR CAMBIO)
-- Cancelado = cancelado (NO PUEDE PEDIR CAMBIO)
-- Asistido = se presento y se concreto el turno   (NO PUEDE PEDIR CAMBIO)
-- Ausente = no vino, puede reagendar pierde la seña.  (PUEDE PEDIR CAMBIO)

-- Especialidades
INSERT INTO Especialidad (NombreEspecialidad, Descripcion) VALUES
('Cardiología', 'Especialidad enfocada en enfermedades del corazón y el sistema circulatorio.'),
('Neurología', 'Diagnóstico y tratamiento de trastornos del sistema nervioso.'),
('Dermatología', 'Tratamiento y diagnóstico de problemas de la piel.');


-- Procedimientos
INSERT INTO Procedimiento (NombreProcedimiento, Descripcion, CostoBase, DuracionMinutos) VALUES
('Electrocardiograma', 'Prueba para medir la actividad eléctrica del corazón.', 2000, 30),
('Resonancia Magnética Cerebral', 'Examen detallado del cerebro mediante imágenes.', 7500, 60),
('Tratamiento Acne', 'Procedimiento dermatológico para controlar el acné.', 1500, 45);
-- Administrador
INSERT INTO CredencialesUsuarios (IdTipoUsuario, Email, Contrasena, Telefono, Dni, Nombre, Apellido, Direccion) VALUES
(1, 'admin@clinicag27.com', 'pass', '123456789', '12345678', 'Admin', 'Clinic', 'Av. Principal 123');
--> Se genera IdUsuario = 1
INSERT INTO UsuarioAdministrador (IdUsuario, FechaInicio) VALUES
(1, '2025-01-01');
GO

-- Doctores
INSERT INTO CredencialesUsuarios (IdTipoUsuario, Email, Contrasena, Telefono, Dni, Nombre, Apellido, Direccion) VALUES
(2, 'doctor1@clinicag27.com', 'pass', '2233445566', '34567890', 'Carlos', 'Cardiólogo', 'Av. Salud 456'),
(2, 'doctor2@clinicag27.com', 'pass', '2233447788', '45678901', 'Luisa', 'Neurologa', 'Calle Científica 23'),
(2, 'doctor3@clinicag27.com', 'pass', '1100223344', '23456789', 'Fernando', 'Sanchez', 'Calle Neuro 789');
--> Se generan IdUsuario = 2 (Carlos), 3 (Luisa), 4 (Fernando)

INSERT INTO Doctor (IdUsuario, NroMatricula, FechaIngreso) VALUES
(2, 'CARD345678', '2020-01-01'), --> Se genera IdDoctor = 1 (Carlos)
(3, 'NEU567890', '2021-06-15'),  --> Se genera IdDoctor = 2 (Luisa)
(4, 'NEU678901', '2023-05-01');  --> Se genera IdDoctor = 3 (Fernando)
GO

-- Pacientes
INSERT INTO CredencialesUsuarios (IdTipoUsuario, Email, Contrasena, Telefono, Dni, Nombre, Apellido, Direccion) VALUES
(3, 'paciente1@gmail.com', 'pass', '1122334455', '56789012', 'Juan', 'Perez', 'Av. Paciente 123'),
(3, 'paciente2@gmail.com', 'pass', '1144556677', '67890123', 'Ana', 'Gomez', 'Calle Esperanza 456'),
(3, 'paciente3@gmail.com', 'pass', '1155667788', '78901234', 'Luis', 'Martinez', 'Av. Libertad 789'),
(3, 'paciente4@gmail.com', 'pass', '1177889966', '89012345', 'Carmen', 'Lopez', 'Calle Unión 456'),
(3, 'paciente5@gmail.com', 'pass', '1199665544', '90123456', 'Santiago', 'Ramirez', 'Calle Central 23'),
(3, 'paciente6@gmail.com', 'pass', '1122553366', '01234567', 'Laura', 'Fernandez', 'Av. Independencia 321');
--> Se generan IdUsuario = 5 (Juan), 6 (Ana), 7 (Luis), 8 (Carmen), 9 (Santiago), 10 (Laura)

INSERT INTO UsuarioPaciente (IdUsuario, FechaRegistro, FechaNacimiento) VALUES
(5, '2025-11-01', '1990-05-15'), --> Se genera IdPaciente = 1 (Juan)
(6, '2025-11-02', '1985-08-25'), --> Se genera IdPaciente = 2 (Ana)
(7, '2025-11-10', '1990-01-23'), --> Se genera IdPaciente = 3 (Luis)
(8, '2025-11-11', '1988-06-15'), --> Se genera IdPaciente = 4 (Carmen)
(9, '2025-11-10', '1995-03-10'), --> Se genera IdPaciente = 5 (Santiago)
(10, '2025-11-12', '1992-09-08');--> Se genera IdPaciente = 6 (Laura)
GO

-- Relación Doctor-Especialidad
INSERT INTO DoctorxEspecialidad (IdDoctor, IdEspecialidad) VALUES
(1, 1), -- Carlos capacitado en Cardiologia
(2, 3); -- Luisa capacitada en Dermatologia
(3, 2); -- Fernando está especializado en Neurología.


-- Procedimientos y especialidad
INSERT INTO ProcedimientoxEspecialidad (IdProcedimiento, IdEspecialidad) VALUES
(1, 1), -- Electrocardiograma pertenece a Cardiología
(2, 2), -- Resonancia Magnética pertenece a Neurología
(3, 3); -- Tratamiento Acne pertenece a Dermatología


-- Pacientes y sus fichas médicas
INSERT INTO FichaMedica (IdPaciente, Alergias) VALUES
(1, 'Penicilina'), --> Se genera FichaMedica = 1 (para Paciente 1 Juan)
(2, DEFAULT),     --> Se genera FichaMedica = 2 (para Paciente 2 Ana)
(3, 'Aspirina'),    --> Se genera FichaMedica = 3 (para Paciente 3 Luis)
(4, 'Ninguna reportada'), --> Se genera FichaMedica = 4 (para Paciente 4 Carmen)
(5, 'Lácteos'),      --> Se genera FichaMedica = 5 (para Paciente 5 Santiago)
(6, 'Ibuprofeno'); --> Se genera FichaMedica = 6 (para Paciente 6 Laura)
GO

-- Turnos
INSERT INTO Turno (IdProcedimiento, IdDoctor, IdPaciente, IdEstadoTurno, FechaTurno, HoraInicio, HoraFin, Monto, FechaCreacion) VALUES
(1, 1, 1, 2, '2025-11-15', '10:00:00', '10:30:00', 2000, '2025-11-01'), --> Turno 1 (Juan, Confirmado)
(2, 2, 2, 1, '2025-11-16', '11:00:00', '12:00:00', 7500, '2025-11-02'), --> Turno 2 (Ana, Reservado)
(3, 2, 1, 1, '2025-11-15', '15:00:00', '16:00:00', 1500, '2025-11-01'), --> Turno 3 (Juan, Reservado)
(1, 1, 2, 5, '2025-11-17', '10:00:00', '10:30:00', 2000, '2025-11-10'), --> Turno 4 (Ana, Ausente)
(1, 1, 3, 1, '2025-11-15', '09:00:00', '09:30:00', 2000, '2025-11-13'), --> Turno 5 (Luis, Reservado)
(2, 3, 4, 2, '2025-11-15', '10:00:00', '11:00:00', 7500, '2025-11-13'), --> Turno 6 (Carmen, Confirmado)
(3, 2, 5, 4, '2025-11-14', '15:00:00', '16:00:00', 1500, '2025-11-12'), --> Turno 7 (Santiago, Asistido)
(1, 1, 6, 5, '2025-11-13', '14:30:00', '15:00:00', 2000, '2025-11-14'); --> Turno 8 (Laura, Ausente)
GO

-- Solicitudes de cambio de turnos
INSERT INTO SolicitudesCambioTurno (IdTurno, IdPaciente, FechaTurnoNueva, HoraInicioNueva, Aprobado, FechaSolicitudCambio) VALUES
(2, 2, '2025-11-18', '10:00:00', 1, '2025-11-12'), -- OK (Turno 2 de Ana está 'Reservado')
(3, 1, '2025-11-20', '09:00:00', 0, '2025-11-14'), -- OK (Turno 3 de Juan está 'Reservado')
(5, 3, '2025-11-16', '09:30:00', 0, '2025-11-14'), -- OK (Turno 5 de Luis está 'Reservado')
(4, 2, '2025-11-19', '11:00:00', 0, '2025-11-18'), -- OK (Turno 4 de Ana está 'Ausente')
(8, 6, '2025-11-17', '14:00:00', 1, '2025-11-14'); -- OK (Turno 8 de Laura está 'Ausente')
GO

-- Ficha Detalle (Historial Clínico)
INSERT INTO FichaDetalle (IdFichaMedica, IdProcedimiento, IdDoctor, Observaciones, FechaCreacion) VALUES
(1, 1, 1, 'Electrocardiograma realizado.', '2025-11-01'), -- Ficha 1 (Juan)
(2, 3, 2, 'Tratamiento acne iniciado.', '2025-11-02'),    -- Ficha 2 (Ana)
(3, 1, 1, 'Electrocardiograma realizado, paciente estable.', '2025-11-13'), -- Ficha 3 (Luis)
(4, 2, 3, 'RM cerebral sin anomalías detectadas.', '2025-11-14'), -- Ficha 4 (Carmen)
(5, 3, 2, 'Tratamiento dermatológico iniciado.', '2025-11-14'), -- Ficha 5 (Santiago)
(6, 1, 1, 'Electrocardiograma solicitado, próxima visita.', '2025-11-15'); -- Ficha 6 (Laura)
GO


---------------------------------------------------------------------- 
