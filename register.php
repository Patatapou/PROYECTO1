<?php
include("conexion.php");

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $nombre_usuario = trim($_POST["nombre_usuario"]);
    $email = trim($_POST["email"]);
    $contraseña = $_POST["contraseña"];
    $confirm_password = $_POST["confirm_password"];

    if (empty($nombre_usuario) || empty($email) || empty($contraseña) || empty($confirm_password)) {
        echo "⚠️ Todos los campos son obligatorios. <a href='register.html'>Volver</a>";
        exit;
    }

    if ($contraseña !== $confirm_password) {
        echo "❌ Las contraseñas no coinciden. <a href='register.html'>Volver</a>";
        exit;
    }

    // Verificar si el usuario o el correo ya existen
    $stmt = $conexion->prepare("SELECT id_usuario FROM Usuario WHERE nombre_usuario = ? OR email = ?");
    $stmt->bind_param("ss", $nombre_usuario, $email);
    $stmt->execute();
    $resultado = $stmt->get_result();

    if ($resultado->num_rows > 0) {
        die("⚠️ El nombre de usuario o correo ya están registrados. <a href='register.html'>Intentar de nuevo</a>");
    }
    $stmt->close();

    // Hashear contraseña (bcrypt)
    $hash = password_hash($contraseña, PASSWORD_BCRYPT);

    // Llamar al procedimiento almacenado registrar_cliente
    $sql = "CALL registrar_cliente(?, ?, ?)";
    $stmt = $conexion->prepare($sql);
    $stmt->bind_param("sss", $nombre_usuario, $email, $hash);

    if ($stmt->execute()) {
        //echo "✅ Registro exitoso. <a href='login.html'>Inicia sesión aquí</a>";
        header("Location: login.html");
    } else {
        echo "❌ Error al registrar: " . $stmt->error;
    }

    $stmt->close();
    $conexion->close();
} else {
    echo "Acceso no permitido.";
}
?>
