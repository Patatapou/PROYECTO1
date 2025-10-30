<?php
include("conexion.php");

// Contraseña real del admin
$password = 'Admin123!';

// Generar hash
$hash = password_hash($password, PASSWORD_BCRYPT);

// Actualizar el usuario admin en la base de datos
$stmt = $conexion->prepare("UPDATE Usuario SET contraseña = ? WHERE nombre_usuario = 'admin'");
$stmt->bind_param("s", $hash);

if ($stmt->execute()) {
    echo "✅ Contraseña del admin actualizada correctamente.";
} else {
    echo "❌ Error: " . $stmt->error;
}

$stmt->close();
$conexion->close();
?>
