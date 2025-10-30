<?php
session_start();
include("conexion.php");

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $nombre_usuario = trim($_POST["nombre_usuario"]);
    $contraseña = $_POST["contraseña"];
    $ip = $_SERVER['REMOTE_ADDR'];
    $token = bin2hex(random_bytes(32));

    // Buscar usuario
    $stmt = $conexion->prepare("SELECT id_usuario, contraseña, tipo_usuario FROM Usuario WHERE nombre_usuario = ?");
    $stmt->bind_param("s", $nombre_usuario);
    $stmt->execute();
    $resultado = $stmt->get_result();

    if ($resultado->num_rows > 0) {
        $usuario = $resultado->fetch_assoc();

        if (password_verify($contraseña, $usuario['contraseña'])) {
            // Contraseña correcta → registrar sesión
            $id_usuario = $usuario['id_usuario'];
            $tipo_usuario = $usuario['tipo_usuario'];

            // Registrar sesión en BD
            $stmt2 = $conexion->prepare("INSERT INTO Sesiones (id_usuario, token, ip_address) VALUES (?, ?, ?)");
            $stmt2->bind_param("iss", $id_usuario, $token, $ip);
            $stmt2->execute();
            $id_sesion = $conexion->insert_id;
            $stmt2->close();

            // Guardar datos en sesión PHP
            $_SESSION['usuario'] = $nombre_usuario;
            $_SESSION['token'] = $token;
            $_SESSION['id_sesion'] = $id_sesion;
            $_SESSION['tipo_usuario'] = $tipo_usuario;

            // Redirección según el tipo de usuario
            if ($tipo_usuario === 'admin') {
                header("Location: admin.html");
            } elseif ($tipo_usuario === 'cliente') {
                header("Location: cliente.php");
            } elseif ($tipo_usuario === 'desarrollador') {
                header("Location: desarrollador.html");
            } else {
                echo "⚠️ Tipo de usuario desconocido.";
            }

            exit; // Importante para detener la ejecución
        } else {
            echo "❌ Contraseña incorrecta. <a href='login.html'>Intentar de nuevo</a>";
        }
    } else {
        echo "⚠️ Usuario no encontrado. <a href='login.html'>Intentar de nuevo</a>";
    }

    $stmt->close();
    $conexion->close();
} else {
    echo "Acceso no permitido.";
}
?>
