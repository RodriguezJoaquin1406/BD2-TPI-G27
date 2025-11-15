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
-- reservado = pago seña
-- confirmado = ya se confirmo fecha y no se da lugar a modificacion de fecha
-- Cancelado = cancelado
-- Asistido = se presento y se concreto el turno
-- Ausente = no vino, puede reagendar pierde la seña.

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

-- Credenciales de usuarios
INSERT INTO CredencialesUsuarios (IdTipoUsuario, Email, Contrasena, Telefono, Dni, Nombre, Apellido, Direccion) VALUES
(1, 'admin@clinicag27.com', 'pass', '123456789', '12345678', 'Admin', 'Clinic', 'Av. Principal 123'),
(2, 'doctor1@clinicag27.com', 'pass', '2233445566', '34567890', 'Carlos', 'Cardiólogo', 'Av. Salud 456'),
(2, 'doctor2@clinicag27.com', 'pass', '2233447788', '45678901', 'Luisa', 'Neurologa', 'Calle Científica 23'),
(3, 'paciente1@gmail.com', 'pass', '1122334455', '56789012', 'Juan', 'Perez', 'Av. Paciente 123'),
(3, 'paciente2@gmail.com', 'pass', '1144556677', '67890123', 'Ana', 'Gomez', 'Calle Esperanza 456');

-- Usuarios Administradores
INSERT INTO UsuarioAdministrador (IdUsuario, FechaInicio) VALUES
(1, '2025-01-01');

-- Usuarios Pacientes
INSERT INTO UsuarioPaciente (IdUsuario, FechaRegistro, FechaNacimiento) VALUES
(4, '2025-11-01', '1990-05-15'),
(5, '2025-11-02', '1985-08-25');

-- Doctores
INSERT INTO Doctor (IdUsuario, NroMatricula, FechaIngreso) VALUES
(2, 'CARD345678', '2020-01-01'),
(3, 'NEU567890', '2021-06-15');

-- Relación Doctor-Especialidad
INSERT INTO DoctorxEspecialidad (IdDoctor, IdEspecialidad) VALUES
(1, 1), -- Carlos capacitado en Cardiologia
(2, 3); -- Luisa capacitada en Dermatologia

-- Pacientes y sus fichas médicas
INSERT INTO FichaMedica (IdPaciente, Alergias) VALUES
(1, 'Penicilina'), 
(2, DEFAULT);

-- Procedimientos y especialidad
INSERT INTO ProcedimientoxEspecialidad (IdProcedimiento, IdEspecialidad) VALUES
(1, 1), -- Electrocardiograma pertenece a Cardiología
(2, 2), -- Resonancia Magnética pertenece a Neurología
(3, 3); -- Tratamiento Acne pertenece a Dermatología

-- Turnos
INSERT INTO Turno (IdProcedimiento, IdDoctor, IdPaciente, IdEstadoTurno, FechaTurno, HoraInicio, HoraFin, Monto, FechaCreacion) VALUES
(1, 1, 1, 2, '2025-11-15', '10:00:00', '10:30:00', 2000, '2025-11-01'),
(2, 2, 2, 1, '2025-11-16', '11:00:00', '12:00:00', 7500, '2025-11-02'),
(3, 2, 1, 1, '2025-11-15', '15:00:00', '16:00:00', 1500, '2025-11-01'), 
(1, 1, 2, 5, '2025-11-17', '10:00:00', '10:30:00', 2000, '2025-11-10'); 

-- Solicitudes de cambio de turnos
INSERT INTO SolicitudesCambioTurno (IdTurno, IdPaciente, FechaTurnoNueva, HoraInicioNueva, Aprobado, FechaSolicitudCambio) VALUES
(2, 2, '2025-11-18', '10:00:00', 1, '2025-11-12'),
(3, 1, '2025-11-20', '09:00:00', 0, '2025-11-14');

-- Ficha Detalle (Historial Clínico)
INSERT INTO FichaDetalle (IdFichaMedica, IdProcedimiento, IdDoctor, Observaciones, FechaCreacion) VALUES
(1, 1, 1, 'Electrocardiograma realizado.', '2025-11-01'),
(2, 3, 2, 'Tratamiento acne iniciado.', '2025-11-02');


---------------------------------------------------------------------- 
