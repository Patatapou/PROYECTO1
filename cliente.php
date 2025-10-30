<?php
session_start();

// Si no hay sesión activa, redirigir al login
if (!isset($_SESSION['usuario'])) {
    header("Location: login.html");
    exit;
}

// Obtener datos del usuario
$nombre_usuario = $_SESSION['usuario'];
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xteam - Tu tienda de videojuegos</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <header>
        <nav class="navbar">
            <a href="index.html" class="logo">Xteam</a>
            <ul class="nav-links">
                <li><a href="index.html">Tienda</a></li>
                <li><a href="biblioteca.html">Biblioteca</a></li>
                <li><a href="carrito.html">Carrito</a></li>
                <li><a href="reviews.html">Reseñas</a></li>
                <li><a href="nosotros.html">Acerca de</a></li>
            </ul>
            <div class="nav-actions">
                <p>Hola <u><?php echo htmlspecialchars($nombre_usuario); ?></u></p>
                <a href="logout.php">Cerrar sesión</a>
            </div>
        </nav>
    </header>

    <main class="container">
        <!-- Aquí va todo tu contenido de juegos y ofertas -->
        <!-- Puedes copiar tal cual lo que ya tienes en cliente.html -->
    </main>

    <footer>
        <a href="nosotros.html#contacto">Contáctanos</a><br><br>
        <p>&copy; 2025 Xteam. Todos los derechos reservados.</p>
    </footer>
</body>
</html>
