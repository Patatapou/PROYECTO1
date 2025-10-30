-- Base de datos MySQL para Xteam
CREATE DATABASE xteam_games;
USE xteam_games;

-- Tabla de usuarios
CREATE TABLE Usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    contraseña VARCHAR(100) NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    tipo_usuario ENUM('cliente', 'desarrollador', 'admin') DEFAULT 'cliente'
);

-- Tabla de clientes (usuarios registrados)
CREATE TABLE Cliente (
    id_usuario INT PRIMARY KEY,
    creditos DECIMAL(10,2) DEFAULT 0 CHECK (creditos >= 0),
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- Tabla de desarrolladores
CREATE TABLE Desarrollador (
    id_usuario INT PRIMARY KEY,
    nombre_estudio VARCHAR(100),
    pais VARCHAR(50),
    sitio_web VARCHAR(200),
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- Tabla de videojuegos
CREATE TABLE Videojuego (
    id_videojuego INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_lanzamiento DATE,
    precio DECIMAL(10,2) CHECK (precio >= 0),
    url_imagen VARCHAR(500),
    id_desarrollador INT NOT NULL,
    requisitos_minimos TEXT,
    requisitos_recomendados TEXT,
    plataforma VARCHAR(50),
    idiomas VARCHAR(200),
    FOREIGN KEY (id_desarrollador) REFERENCES Desarrollador(id_usuario) ON DELETE CASCADE
);

-- Tabla de categorías
CREATE TABLE Categoria (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL UNIQUE
);

-- Tabla de relación videojuego-categoría
CREATE TABLE VideojuegoCategoria (
    id_videojuego INT,
    id_categoria INT,
    PRIMARY KEY (id_videojuego, id_categoria),
    FOREIGN KEY (id_videojuego) REFERENCES Videojuego(id_videojuego) ON DELETE CASCADE,
    FOREIGN KEY (id_categoria) REFERENCES Categoria(id_categoria) ON DELETE CASCADE
);

-- Tabla de compras
CREATE TABLE Compra (
    id_compra INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    fecha_compra DATETIME DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10,2) CHECK (total >= 0),
    metodo_pago ENUM('tarjeta', 'paypal', 'creditos'),
    estado ENUM('pendiente', 'completada', 'cancelada') DEFAULT 'pendiente',
    FOREIGN KEY (id_usuario) REFERENCES Cliente(id_usuario) ON DELETE SET NULL
);

-- Tabla de detalles de compra
CREATE TABLE DetalleCompra (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_compra INT NOT NULL,
    id_videojuego INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_compra) REFERENCES Compra(id_compra) ON DELETE CASCADE,
    FOREIGN KEY (id_videojuego) REFERENCES Videojuego(id_videojuego) ON DELETE CASCADE
);

-- Tabla de biblioteca (juegos adquiridos)
CREATE TABLE Biblioteca (
    id_biblioteca INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    id_videojuego INT,
    fecha_adquirido DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_usuario, id_videojuego),
    FOREIGN KEY (id_usuario) REFERENCES Cliente(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_videojuego) REFERENCES Videojuego(id_videojuego) ON DELETE CASCADE
);

-- Tabla de reseñas
CREATE TABLE Reseña (
    id_usuario INT NOT NULL,
    id_videojuego INT NOT NULL,
    calificacion INT CHECK (calificacion BETWEEN 1 AND 5),
    comentario TEXT,
    fecha_reseña DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario, id_videojuego),
    FOREIGN KEY (id_usuario) REFERENCES Cliente(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_videojuego) REFERENCES Videojuego(id_videojuego) ON DELETE CASCADE
);

-- Tabla de transacciones
CREATE TABLE Transaccion (
    id_transaccion INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    tipo ENUM('compra', 'reembolso', 'recarga'),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    monto DECIMAL(10,2) NOT NULL,
    descripcion VARCHAR(200),
    FOREIGN KEY (id_usuario) REFERENCES Cliente(id_usuario) ON DELETE SET NULL
);

-- Tabla de recibos (PDF)
CREATE TABLE Recibo (
    id_recibo INT AUTO_INCREMENT PRIMARY KEY,
    id_compra INT NOT NULL,
    nombre_archivo VARCHAR(255),
    fecha_generacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    contenido LONGBLOB,
    FOREIGN KEY (id_compra) REFERENCES Compra(id_compra) ON DELETE CASCADE
);

-- Tabla de sesiones
CREATE TABLE Sesiones (
    id_sesion INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    token VARCHAR(255) NOT NULL UNIQUE,
    ip_address VARCHAR(45),
    fecha_inicio DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_ultima_actividad DATETIME DEFAULT CURRENT_TIMESTAMP,
    activa BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- Índices para mejor rendimiento
CREATE INDEX idx_videojuego_titulo ON Videojuego(titulo);
CREATE INDEX idx_reseña_videojuego ON Reseña(id_videojuego);
CREATE INDEX idx_compra_usuario ON Compra(id_usuario);
CREATE INDEX idx_biblioteca_usuario ON Biblioteca(id_usuario);
CREATE INDEX idx_sesiones_token ON Sesiones(token);
CREATE INDEX idx_sesiones_usuario ON Sesiones(id_usuario);


-- Procedures
-- Registrar nuevo cliente
DELIMITER //
CREATE PROCEDURE registrar_cliente(
    IN p_nombre_usuario VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_contraseña VARCHAR(100)
)
BEGIN
    DECLARE v_id_usuario INT;
    
    START TRANSACTION;
    
    -- Insertar en la tabla Usuario
    INSERT INTO Usuario (nombre_usuario, email, contraseña, tipo_usuario)
    VALUES (p_nombre_usuario, p_email, p_contraseña, 'cliente');
    
    SET v_id_usuario = LAST_INSERT_ID();
    
    -- Insertar en la tabla Cliente
    INSERT INTO Cliente (id_usuario)
    VALUES (v_id_usuario);
    
    COMMIT;
END //
DELIMITER ;

-- Iniciar sesión
DELIMITER //
CREATE PROCEDURE login_usuario(
    IN p_nombre_usuario VARCHAR(50),
    IN p_contraseña VARCHAR(100),
    IN p_ip VARCHAR(45),
    IN p_token VARCHAR(255),
    OUT p_id_sesion INT
)
BEGIN
    DECLARE v_id_usuario INT;
    
    -- Validar credenciales
    SELECT id_usuario INTO v_id_usuario
    FROM Usuario
    WHERE nombre_usuario = p_nombre_usuario
      AND contraseña = p_contraseña;
    
    IF v_id_usuario IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario o contraseña incorrectos';
    END IF;
    
    -- Registrar sesión
    INSERT INTO Sesiones (id_usuario, token, ip_address)
    VALUES (v_id_usuario, p_token, p_ip);
    
    SET p_id_sesion = LAST_INSERT_ID();
END //
DELIMITER ;

-- Procesar compra
DELIMITER //
CREATE PROCEDURE procesar_compra(
    IN p_id_usuario INT,
    IN p_id_videojuego INT,
    IN p_metodo_pago ENUM('tarjeta', 'paypal', 'creditos'),
    OUT p_id_compra INT
)
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_creditos DECIMAL(10,2);
    DECLARE v_id_compra INT;
    
    START TRANSACTION;
    
    -- Obtener precio del videojuego
    SELECT precio INTO v_precio
    FROM Videojuego
    WHERE id_videojuego = p_id_videojuego;
    
    -- Si el usuario está registrado, verificar créditos
    IF p_id_usuario IS NOT NULL THEN
        SELECT creditos INTO v_creditos
        FROM Cliente
        WHERE id_usuario = p_id_usuario;
        
        -- Si paga con créditos, verificar que tenga suficientes
        IF p_metodo_pago = 'creditos' AND v_creditos < v_precio THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Créditos insuficientes';
        END IF;
    END IF;
    
    -- Crear compra
    INSERT INTO Compra (id_usuario, total, metodo_pago, estado)
    VALUES (p_id_usuario, v_precio, p_metodo_pago, 'completada');
    
    SET v_id_compra = LAST_INSERT_ID();
    SET p_id_compra = v_id_compra;
    
    -- Agregar detalle de compra
    INSERT INTO DetalleCompra (id_compra, id_videojuego, precio_unitario)
    VALUES (v_id_compra, p_id_videojuego, v_precio);
    
    -- Si el usuario está registrado, agregar a biblioteca y actualizar créditos
    IF p_id_usuario IS NOT NULL THEN
        INSERT INTO Biblioteca (id_usuario, id_videojuego)
        VALUES (p_id_usuario, p_id_videojuego);
        
        -- Si paga con créditos, descontarlos
        IF p_metodo_pago = 'creditos' THEN
            UPDATE Cliente
            SET creditos = creditos - v_precio
            WHERE id_usuario = p_id_usuario;
        END IF;
        
        -- Registrar transacción
        INSERT INTO Transaccion (id_usuario, tipo, monto, descripcion)
        VALUES (p_id_usuario, 'compra', v_precio, CONCAT('Compra de videojuego ID: ', p_id_videojuego));
    END IF;
    
    COMMIT;
END //
DELIMITER ;

-- Agregar créditos a usuario
DELIMITER //
CREATE PROCEDURE agregar_creditos(
    IN p_id_usuario INT,
    IN p_monto DECIMAL(10,2)
)
BEGIN
    START TRANSACTION;
    
    UPDATE Cliente
    SET creditos = creditos + p_monto
    WHERE id_usuario = p_id_usuario;
    
    INSERT INTO Transaccion (id_usuario, tipo, monto, descripcion)
    VALUES (p_id_usuario, 'recarga', p_monto, 'Recarga de créditos');
    
    COMMIT;
END //
DELIMITER ;

-- Función para obtener calificación promedio
DELIMITER //
CREATE FUNCTION promedio_calificacion(p_id_videojuego INT)
RETURNS DECIMAL(3,2)
READS SQL DATA
BEGIN
    DECLARE v_promedio DECIMAL(3,2);
    
    SELECT AVG(calificacion) INTO v_promedio
    FROM Reseña
    WHERE id_videojuego = p_id_videojuego;
    
    RETURN COALESCE(v_promedio, 0);
END //
DELIMITER ;

-- Función para contar juegos en biblioteca
DELIMITER //
CREATE FUNCTION contar_juegos_biblioteca(p_id_usuario INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_total INT;
    
    SELECT COUNT(*) INTO v_total
    FROM Biblioteca
    WHERE id_usuario = p_id_usuario;
    
    RETURN COALESCE(v_total, 0);
END //
DELIMITER ;


-- VISTAS
-- Vista del catálogo de videojuegos
CREATE VIEW vw_catalogo_videojuegos AS
SELECT 
    v.id_videojuego,
    v.titulo,
    v.descripcion,
    v.fecha_lanzamiento,
    v.precio,
    v.url_imagen,
    v.plataforma,
    v.idiomas,
    d.nombre_estudio AS desarrollador,
    d.pais,
    (SELECT AVG(calificacion) FROM Reseña r WHERE r.id_videojuego = v.id_videojuego) AS calificacion_promedio,
    (SELECT COUNT(*) FROM Reseña r WHERE r.id_videojuego = v.id_videojuego) AS total_resenas
FROM Videojuego v
JOIN Desarrollador d ON v.id_desarrollador = d.id_usuario;

-- Vista de videojuegos con categorías
CREATE VIEW vw_videojuego_categorias AS
SELECT 
    v.id_videojuego,
    v.titulo,
    GROUP_CONCAT(c.nombre_categoria SEPARATOR ', ') AS categorias
FROM Videojuego v
JOIN VideojuegoCategoria vc ON v.id_videojuego = vc.id_videojuego
JOIN Categoria c ON vc.id_categoria = c.id_categoria
GROUP BY v.id_videojuego, v.titulo;

-- Vista de biblioteca de usuarios
CREATE VIEW vw_biblioteca_usuarios AS
SELECT 
    u.nombre_usuario,
    v.titulo,
    v.url_imagen,
    b.fecha_adquirido,
    v.id_videojuego,
    u.id_usuario
FROM Biblioteca b
JOIN Videojuego v ON b.id_videojuego = v.id_videojuego
JOIN Usuario u ON b.id_usuario = u.id_usuario;

-- Vista para panel de administración
CREATE VIEW vw_estadisticas_admin AS
SELECT 
    (SELECT COUNT(*) FROM Usuario WHERE tipo_usuario = 'cliente') AS total_clientes,
    (SELECT COUNT(*) FROM Usuario WHERE tipo_usuario = 'desarrollador') AS total_desarrolladores,
    (SELECT COUNT(*) FROM Videojuego) AS total_videojuegos,
    (SELECT COUNT(*) FROM Compra WHERE estado = 'completada') AS total_ventas,
    (SELECT SUM(total) FROM Compra WHERE estado = 'completada') AS ingresos_totales,
    (SELECT COUNT(*) FROM Reseña) AS total_resenas;
    
    

-- pdfs
CREATE TABLE Recibo (
    id_recibo INT AUTO_INCREMENT PRIMARY KEY,
    id_compra INT NOT NULL,
    nombre_archivo VARCHAR(255),
    fecha_generacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    contenido LONGBLOB,
    FOREIGN KEY (id_compra) REFERENCES Compra(id_compra) ON DELETE CASCADE
);

-- Metodo pago
-- Tabla para métodos de pago del usuario
CREATE TABLE MetodosPago (
    id_metodo_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    tipo ENUM('tarjeta', 'paypal') NOT NULL,
    titular VARCHAR(100),
    -- Para tarjetas
    numero_tarjeta VARCHAR(20),
    fecha_vencimiento VARCHAR(7), -- MM/YYYY
    cvv VARCHAR(4),
    -- Para PayPal
    email_paypal VARCHAR(100),
    token_paypal VARCHAR(255),
    -- Metadata
    predeterminado BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- Tabla de transacciones de pago
CREATE TABLE TransaccionesPago (
    id_transaccion_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_compra INT NOT NULL,
    metodo_pago ENUM('tarjeta', 'paypal', 'creditos') NOT NULL,
    id_metodo_pago INT, -- Referencia al método específico usado
    monto DECIMAL(10,2) NOT NULL,
    estado ENUM('pendiente', 'completada', 'fallida', 'reembolsada') DEFAULT 'pendiente',
    id_transaccion_externo VARCHAR(255), -- ID de PayPal/Stripe
    datos_transaccion JSON, -- Respuesta completa del procesador
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_compra) REFERENCES Compra(id_compra) ON DELETE CASCADE,
    FOREIGN KEY (id_metodo_pago) REFERENCES MetodosPago(id_metodo_pago) ON DELETE SET NULL
);

-- Modificar tabla Compra para más detalles de pago
ALTER TABLE Compra 
ADD COLUMN id_transaccion_pago INT AFTER metodo_pago,
ADD COLUMN direccion_facturacion TEXT AFTER estado,
ADD FOREIGN KEY (id_transaccion_pago) REFERENCES TransaccionesPago(id_transaccion_pago);