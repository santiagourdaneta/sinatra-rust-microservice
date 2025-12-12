# ⚡ Proyecto Ultra-Rápido | Sinatra & Rust Performance Microservice

## 🌟 Descripción del Proyecto

Este proyecto es una demostración de una arquitectura de servidor web de **alto rendimiento y baja latencia**. Utiliza la simplicidad y robustez de **Ruby con Sinatra** para gestionar las rutas, la seguridad (CSRF, Rate Limiting) y la interfaz de usuario, mientras delega las tareas computacionales intensivas a un **microservicio compilado en Rust**.

El objetivo es simular un trabajo pesado de *backend* (generación masiva de texto) y demostrar cómo Rust puede reducir drásticamente los tiempos de latencia en comparación con un lenguaje interpretado/JIT.


## 🎯 Puntos Clave

* **Velocidad Extrema:** Medición en tiempo real de la latencia (ms) del motor Rust.
* **Arquitectura Híbrida:** Ruby actúa como la capa de API y seguridad, Rust como el motor de cálculo.
* **Seguridad Web:** Implementación de *Rate Limiting* (Limitación de Tasa) y protección CSRF.
* **Configuración Segura:** Uso de archivos `.env` y `.gitignore` para manejar secretos y variables de entorno.

## ⚙️ Tecnologías Utilizadas

| Componente | Tecnología | Rol |
| :--- | :--- | :--- |
| **Servidor** | Ruby 3.x (Sinatra) | Enrutamiento, Seguridad, Orquestación. |
| **Motor** | Rust (Compilado) | Generación de texto masiva (Baja Latencia). |
| **Frontend** | HTML5, CSS3 | Interfaz de usuario adaptable (*Responsive*). |
| **Lógica Cliente** | TypeScript / JavaScript | Interacción, Cronómetro UX, Peticiones `fetch`. |
| **Entorno** | Node.js (npm) | Herramientas de *build* y minificación. |

## 🚀 Instalación y Ejecución

Sigue estos pasos para levantar el proyecto en tu máquina local (asumiendo Windows, Ruby y Rust instalados).

### 1. Preparación de la Carpeta

```bash
# Navega a la carpeta principal
cd /sinatra-rust-microservice

# Instalar dependencias de Ruby
gem install sinatra sinatra-contrib rack-protection html-minifier dotenv json puma

# Instalar dependencias de Node.js (para minificación/TS)
npm install

2. Compilar el Binario de Rust

Navega a la carpeta de Rust y compila la versión optimizada:

cd rust_generator
cargo build --release

Esto creará el binario en rust_generator/target/release/rust_generator.exe

3. Configurar la Variable de Entorno

Crea el archivo .env en la raíz del proyecto (sinatra-rust-microservice/.env) y establece la ruta absoluta a tu binario compilado.

4. Compilar el Frontend

Ejecuta el script para compilar TypeScript y aplicar el hash a los archivos estáticos:

npm run build:all

5. Iniciar el Servidor

Ejecuta el servidor Ruby (con hot-reloading habilitado para desarrollo):

ruby app.rb

Abre tu navegador en http://localhost:4567 para ver el resultado.

📝 Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo LICENSE.md para más detalles.

Labels / Tags (Temas)	

ruby, sinatra, rust, microservices, performance, web-development, high-speed, benchmark

Hashtags para Redes	

#RubySinatra #RustPerformance #Microservice #WebSpeed #HighPerformanceComputing





