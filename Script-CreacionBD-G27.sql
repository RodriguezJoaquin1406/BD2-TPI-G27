-- ====================================
-- ## SCRIPT CREACION BD GRUPO 27 ## --
-- ## CLINICA - JOAQUIN RODRIGUEZ ## --
-- ====================================

USE MASTER
GO

CREATE DATABASE BD2_TPI_G27_CLINICA
GO

USE BD2_TPI_G27_CLINICA
GO

-- ======================
-- CREACION DE TABLAS 
-- ======================

CREATE TABLE TiposUsuarios (
    IdTipoUsuario TINYINT PRIMARY KEY IDENTITY(1,1),
    Descripcion VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE EstadosTurnos (
    IdEstado TINYINT PRIMARY KEY IDENTITY(1,1),
    Detalle VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Especialidad (
    IdEspecialidad INT PRIMARY KEY IDENTITY(1,1),
    NombreEspecialidad VARCHAR(100) NOT NULL UNIQUE,
    Descripcion VARCHAR(500)
);
GO


CREATE TABLE Procedimiento (
    IdProcedimiento INT PRIMARY KEY IDENTITY(1,1),
    NombreProcedimiento VARCHAR(100) NOT NULL UNIQUE,
    Descripcion VARCHAR(500),
    CostoBase DECIMAL(10, 2) NOT NULL,
    DuracionMinutos INT NOT NULL,
    
    CONSTRAINT CHK_Procedimiento_CostoPositivo CHECK (CostoBase >= 0),
    CONSTRAINT CHK_Procedimiento_DuracionPositiva CHECK (DuracionMinutos > 0)
);
GO


CREATE TABLE CredencialesUsuarios (
    IdUsuario INT PRIMARY KEY IDENTITY(1,1),
    IdTipoUsuario TINYINT NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Contrasena VARCHAR(255) NOT NULL, 
    Telefono VARCHAR(25) NOT NULL,
    Dni VARCHAR(20) NOT NULL UNIQUE,
    Nombre VARCHAR(100) NOT NULL,
    Apellido VARCHAR(100) NOT NULL,
    Direccion VARCHAR(255),

    CONSTRAINT FK_Usuario_TipoUsuario FOREIGN KEY (IdTipoUsuario) REFERENCES TiposUsuarios(IdTipoUsuario) 
);


CREATE TABLE UsuarioAdministrador (
    IdAdministrador INT PRIMARY KEY IDENTITY(1,1),
    IdUsuario INT NOT NULL UNIQUE,
    FechaInicio DATE NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_Admin_Credenciales FOREIGN KEY (IdUsuario) REFERENCES CredencialesUsuarios(IdUsuario) 
);

CREATE TABLE UsuarioPaciente (
    IdPaciente INT PRIMARY KEY IDENTITY(1,1),
    IdUsuario INT NOT NULL UNIQUE,
    FechaRegistro DATETIME NOT NULL DEFAULT GETDATE(),
    FechaNacimiento DATE,
    
    CONSTRAINT FK_Paciente_Credenciales FOREIGN KEY (IdUsuario) REFERENCES CredencialesUsuarios(IdUsuario) 
);

CREATE TABLE Doctor(
    IdDoctor INT PRIMARY KEY IDENTITY(1,1),
    IdUsuario INT NOT NULL UNIQUE,
    NroMatricula VARCHAR(50) NOT NULL UNIQUE,
    FechaIngreso DATE NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_Doctor_Credenciales FOREIGN KEY (IdUsuario) REFERENCES CredencialesUsuarios(IdUsuario) 
);
GO


CREATE TABLE FichaMedica (
    IdFichaMedica INT PRIMARY KEY IDENTITY(1,1),
    IdPaciente INT NOT NULL UNIQUE, 
    Alergias VARCHAR(1000) DEFAULT 'Sin Alergias',
    
    CONSTRAINT FK_Ficha_Paciente FOREIGN KEY (IdPaciente) REFERENCES UsuarioPaciente(IdPaciente) 
);

CREATE TABLE Turno (
    IdTurno INT PRIMARY KEY IDENTITY(1,1),
    IdProcedimiento INT NOT NULL,
    IdDoctor INT NOT NULL,
    IdPaciente INT NOT NULL,
    IdEstadoTurno TINYINT NOT NULL,
    FechaTurno DATE NOT NULL,
    HoraInicio TIME NOT NULL,
    HoraFin TIME NOT NULL,
    Monto DECIMAL(10, 2) NOT NULL,
    FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_Turno_Procedimiento FOREIGN KEY (IdProcedimiento) REFERENCES Procedimiento(IdProcedimiento) ,
    CONSTRAINT FK_Turno_Doctor FOREIGN KEY (IdDoctor) REFERENCES Doctor(IdDoctor) ,
    CONSTRAINT FK_Turno_Paciente FOREIGN KEY (IdPaciente) REFERENCES UsuarioPaciente(IdPaciente) ,
    CONSTRAINT FK_Turno_Estado FOREIGN KEY (IdEstadoTurno) REFERENCES EstadosTurnos(IdEstado) ,
    CONSTRAINT CHK_Turno_MontoPositivo CHECK (Monto >= 0),
    CONSTRAINT CHK_Turno_HoraFinMayor CHECK (HoraFin > HoraInicio)
);

CREATE TABLE SolicitudesCambioTurno (
    IdSolicitud INT PRIMARY KEY IDENTITY(1,1),
    IdTurno INT NOT NULL,
    IdPaciente INT NOT NULL,
    FechaTurnoNueva DATE NOT NULL,
    HoraInicioNueva TIME NOT NULL,  -- nuevo para saber hora 
    Aprobado BIT DEFAULT 0, -- 0 = Pendiente, 1 = Aprobado
    FechaSolicitudCambio DATETIME NOT NULL DEFAULT GETDATE(),  --  nuevo para saber cuando se creó la solicitud
    
    CONSTRAINT FK_Solicitud_Turno FOREIGN KEY (IdTurno) REFERENCES Turno(IdTurno) ,
    CONSTRAINT FK_Solicitud_Paciente FOREIGN KEY (IdPaciente) REFERENCES UsuarioPaciente(IdPaciente)
);
GO

CREATE TABLE FichaDetalle (
    IdHistorial INT PRIMARY KEY IDENTITY(1,1),
    IdFichaMedica INT NOT NULL,
    IdProcedimiento INT NOT NULL,
    IdDoctor INT NOT NULL,
    Observaciones VARCHAR(2000),
    FechaCreacion DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_Detalle_FichaMedica FOREIGN KEY (IdFichaMedica) REFERENCES FichaMedica(IdFichaMedica) ,
    CONSTRAINT FK_Detalle_Procedimiento FOREIGN KEY (IdProcedimiento) REFERENCES Procedimiento(IdProcedimiento) ,
    CONSTRAINT FK_Detalle_Doctor FOREIGN KEY (IdDoctor) REFERENCES Doctor(IdDoctor) 
);
GO

-- Tablas Intermedias (Muchos a Muchos)

CREATE TABLE DoctorxEspecialidad (
    IdDoctor INT NOT NULL,
    IdEspecialidad INT NOT NULL,
    
    CONSTRAINT PK_Doctor_Especialidad PRIMARY KEY (IdDoctor, IdEspecialidad), -- Clave Primaria Compuesta
    CONSTRAINT FK_DxE_Doctor FOREIGN KEY (IdDoctor) REFERENCES Doctor(IdDoctor) ,
    CONSTRAINT FK_DxE_Especialidad FOREIGN KEY (IdEspecialidad) REFERENCES Especialidad(IdEspecialidad) 
);

CREATE TABLE ProcedimientoxEspecialidad (
    IdProcedimiento INT NOT NULL,
    IdEspecialidad INT NOT NULL,
    
    CONSTRAINT PK_Procedimiento_Especialidad PRIMARY KEY (IdProcedimiento, IdEspecialidad), -- Clave Primaria Compuesta
    CONSTRAINT FK_PxE_Procedimiento FOREIGN KEY (IdProcedimiento) REFERENCES Procedimiento(IdProcedimiento) ,
    CONSTRAINT FK_PxE_Especialidad FOREIGN KEY (IdEspecialidad) REFERENCES Especialidad(IdEspecialidad) 
);
GO