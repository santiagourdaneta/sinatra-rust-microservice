require 'sinatra'
require 'json'
require 'securerandom'
require 'html_minifier'
require 'dotenv/load' 
require 'sinatra/reloader' 

# ------------------------------------------------
# VARIABLES GLOBALES DE SEGURIDAD 
# ------------------------------------------------
# Define las constantes solo si no han sido definidas antes (por el reloader)

unless defined?(RATE_LIMIT_MAX_REQUESTS)
  $rate_limit_store = {} 
  RATE_LIMIT_MAX_REQUESTS = 5  
  RATE_LIMIT_WINDOW_SECONDS = 60
end

# Define la ruta binaria solo si no ha sido definida antes
unless defined?(RUST_BINARY_PATH)
  RUST_BINARY_PATH = ENV['RUST_BINARY_PATH'] 
  
  # Comprobación de seguridad: Si no encuentra la ruta, muestra un error claro.
  if RUST_BINARY_PATH.nil? || RUST_BINARY_PATH.empty?
    $stderr.puts "ERROR: RUTA DE RUST NO ENCONTRADA. Asegúrate de configurar la variable RUST_EXECUTABLE_PATH en el archivo .env"
    exit 1
  end
end

# ------------------------------
# SEGURIDAD Y OPTIMIZACION
# ------------------------------

# Configura las sesiones, el token CSRF y la carpeta pública para archivos estáticos
configure do
  set :public_folder, 'public' 
  # ---------------------------------
  set :session_secret, SecureRandom.hex(64)
  enable :sessions
end

# --- HOT RELOAD ---
configure :development do
  # Esto solo se ejecuta cuando el entorno es 'development' (por defecto al usar 'ruby app.rb')
  require 'sinatra/reloader'
  register Sinatra::Reloader
end
# ---------------------------------------------

# Middleware para generar el token CSRF si no existe
before do
  session[:csrf_token] ||= SecureRandom.hex(32)
end

# Función de Verificación CSRF (CSRF Token)
def check_csrf
  submitted_token = env['HTTP_X_CSRF_TOKEN'] # Viene del header de TypeScript
  expected_token = session[:csrf_token]

  unless submitted_token == expected_token && submitted_token
    content_type :json
    halt 403, '{"error": "403 Forbidden: CSRF Token Inválido o faltante."}'
  end
end

# Función de Rate Limiting (Protección DDoS/Abuso)
def check_rate_limit(ip_address)
  current_time = Time.now
  
  # Inicializa el registro para esta IP si no existe
  if $rate_limit_store[ip_address].nil?
    $rate_limit_store[ip_address] = { count: 0, last_window: current_time }
  end
  
  ip_data = $rate_limit_store[ip_address]
  
  # Si ha pasado más de un minuto (la ventana de tiempo), reinicia el contador
  if current_time - ip_data[:last_window] > RATE_LIMIT_WINDOW_SECONDS
    ip_data[:count] = 0
    ip_data[:last_window] = current_time
  end
  
  # Incrementa el contador
  ip_data[:count] += 1
  
  # Chequea si el límite ha sido excedido
  if ip_data[:count] > RATE_LIMIT_MAX_REQUESTS
    status 429 # Too Many Requests
    halt({ error: "Límite de peticiones excedido. Intenta de nuevo en #{RATE_LIMIT_WINDOW_SECONDS} segundos." }.to_json, "Content-Type" => "application/json")
  end
end

# Función para inyectar Meta Tags de SEO
def headers_seo_ux(csrf_token)

  <<-HTML
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Desarrollado con Rust Typescript y Ruby.">
    <meta name="csrf-token" content="#{csrf_token}">
    
    <meta property="og:title" content="Generador de texto ultra-rápido sobre el calentamiento global.">
    <meta property="og:description" content="Desarrollado con Rust Typescript y Ruby.">
    <meta property="og:type" content="website">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="Generador de texto ultra-rápido sobre el calentamiento global.">
    <link rel="stylesheet" href="/style.css" fetchpriority="high">
  HTML
end

# ------------------------------
# RUTAS
# ------------------------------

# 1. Ruta Principal (HTML-first + Minificación)
get '/' do
  # 1. Generar todo el HTML de la vista
  html_final = erb(:index, :layout => false, :locals => { :csrf_token => session[:csrf_token] })
  
  # 2. Minimizar el HTML 
  begin
    minified_html = HtmlMinifier.minify(html_final.strip, {
      :remove_comments => true,
      :remove_intertag_spaces => true
    })
    minified_html
  rescue
    # Si la minificación falla, enviar el HTML normal 
    html_final
  end
end

# ------------------------------
# 2. Ruta para Generar Texto (Aplicando Seguridad y Latencia)
# ------------------------------
post '/generar_texto' do
  content_type :json

  # 1. Chequeos de Seguridad 
  check_csrf
  check_rate_limit(request.ip) # Limita las peticiones por IP

  # El cuerpo de la petición es JSON, lo parseamos
  begin
    data = JSON.parse(request.body.read)
  rescue JSON::ParserError
    status 400
    return { error: "Formato JSON inválido." }.to_json
  end
  
  begin
    chars = data['chars'].to_i
    
    # 2. Validación de Entrada (Evitar que el usuario envíe basura)
    unless [100, 1000, 10000].include?(chars)
      status 400
      return { error: "Cantidad de caracteres no válida." }.to_json
    end
    
    # 3. Medición de Latencia de Rust
    start_time = Time.now # Captura el tiempo antes de llamar a Rust
    generated_text = ""
    
    # 4. Ejecuta el binario de Rust y pasa la cantidad de caracteres
    # IO.popen permite a Ruby ejecutar un programa externo y leer su output.
    IO.popen("#{RUST_BINARY_PATH} #{chars}") do |io|
      generated_text = io.read # Ruby lee el texto generado por Rust
    end

    end_time = Time.now # Captura el tiempo después de la ejecución de Rust
    
    # Calcula la diferencia en milisegundos y redondea a dos decimales
    latency_ms = ((end_time - start_time) * 1000).round(2) 

    # 5. Respuesta Final
    if generated_text && !generated_text.empty?
      # Devuelve el texto generado Y la latencia medida
      { text: generated_text.strip, latency: latency_ms }.to_json
    else
      status 500
      { error: "Error de ejecución del motor Rust. Verifique la ruta binaria o la compilación." }.to_json
    end

  rescue StandardError => e
    # Captura cualquier otro error durante la ejecución (ej: ruta de Rust incorrecta)
    status 500
    { error: "Error interno del servidor: No se pudo ejecutar el microservicio Rust. (Detalles: #{e.message})" }.to_json
  end
end


__END__

@@ index
<!DOCTYPE html>
<html lang="es">
<head>
    <%= headers_seo_ux(locals[:csrf_token]) %>
    <title>Generador de texto ultra-rápido sobre el calentamiento global.</title> 
</head>
<body class="bg-blue-0-20"> 
    <main>
        <h1>Generador de texto ultra-rápido sobre el calentamiento global.</h1>

        <div class="control-group">
                    <h2 class="instruction-text">
                        Desliza (0 a 40) de izquierda a derecha para cambiar la tonalidad de la interfaz.
                    </h2>
                    <div class="slider-container">
                        <input type="range" id="rangeSlider" min="0" max="40" value="0">
                        <span id="rangeValue">0</span>
                    </div>
                </div>

       <div class="control-group">
                   <h2>Selecciona la Cantidad de Caracteres (Generación con Rust)</h2>
                   <div id="characterOptions" class="button-group">
                       <button data-chars="100" class="option-btn">100 Chars</button>
                       <button data-chars="1000" class="option-btn">1K Chars</button>
                       <button data-chars="10000" class="option-btn">10K Chars</button>

                     <div id="processInfo" class="process-info" style="display:none;">
                    <span id="loadingIndicator" class="loading-indicator">Generando texto...</span>
                    <span id="timerDisplay" class="timer-display"></span>
                </div>
                </div>
        </div>
               
               <div class="output-container">
                   <textarea id="output" readonly placeholder="El texto generado a velocidad extrema aparecerá aquí..."></textarea>
                   <button id="copyButton" class="action-btn">
                       Copiar Texto (Clipboard)
                   </button>
               </div>

        <div id="loadingIndicator" style="display:none;">Generando texto...</div>
    </main>

    <footer>
        <p>Proyecto Ultra-Rápido ⚡ | Ruby (Sinatra) + Rust (Rendimiento) + TypeScript (Frontend)</p>
        <p>&copy; 2025 | Generador de texto ultra-rápido sobre el calentamiento global</p>
    </footer>

    <script src="/script.62b512c9.min.js" defer></script> 
</body>
</html>


