# language: es

@autenticacion @seguridad
Característica: Inicio de sesión
  Como usuario registrado
  Quiero iniciar sesión en la plataforma
  Para acceder a mi cuenta personal

  Antecedentes:
    Dado que la página de inicio de sesión está disponible
    Y el servicio de autenticación está activo

  Escenario: Inicio de sesión exitoso
    Dado un usuario con email "carlos@ejemplo.es"
    Y una contraseña válida "MiClave#2025"
    Cuando ingreso mis credenciales
    Entonces accedo al panel principal
    Y se muestra un mensaje de bienvenida

  Escenario: Inicio de sesión fallido por contraseña incorrecta
    Dado un usuario con email "carlos@ejemplo.es"
    Y una contraseña incorrecta "clave_erronea"
    Cuando ingreso mis credenciales
    Entonces se muestra el error "Credenciales inválidas"
    Pero la cuenta no se bloquea

  Esquema del escenario: Validación de campos obligatorios
    Dado que dejo el campo "<campo>" vacío
    Cuando intento iniciar sesión
    Entonces se muestra el error "<mensaje>"

    Ejemplos:
      | campo      | mensaje                         |
      | email      | El email es obligatorio         |
      | contraseña | La contraseña es obligatoria    |
