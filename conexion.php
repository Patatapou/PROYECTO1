<?php
$host = "localhost";
$usuario = "root";      
$clave = "";            
$bd = "xteam_games";

$conexion = new mysqli($host, $usuario, $clave, $bd);

// Verificar conexión
if ($conexion->connect_error) {
    die("Error en la conexión: " . $conexion->connect_error);
} else {
    echo "Conexión exitosa a la base de datos";
}
