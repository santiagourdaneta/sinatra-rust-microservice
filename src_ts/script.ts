// script.ts
document.addEventListener('DOMContentLoaded', () => {
    // 1. Obtener elementos DOM
    const slider = document.getElementById('rangeSlider') as HTMLInputElement;
    const body = document.body;
    const rangeValueDisplay = document.getElementById('rangeValue') as HTMLSpanElement;
    const characterOptions = document.getElementById('characterOptions') as HTMLElement;
    const output = document.getElementById('output') as HTMLTextAreaElement;
    const copyButton = document.getElementById('copyButton') as HTMLButtonElement;
    
    // --- ELEMENTOS PARA EL CRONÓMETRO Y FEEDBACK ---
    const processInfo = document.getElementById('processInfo') as HTMLElement;
    const loading = document.getElementById('loadingIndicator') as HTMLElement;
    const timerDisplay = document.getElementById('timerDisplay') as HTMLSpanElement;
    
    // 2. Obtener el Token CSRF del HTML (El pase secreto)
    const csrfMeta = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement;
    const csrfToken = csrfMeta ? csrfMeta.content : '';

    // Variables de control del tiempo
    let startTime: number;
    let timerInterval: number | undefined;

    // Función para manejar errores de la API
    function displayError(message: string) {
        output.value = `ERROR: ${message}`;
        stopTimer(); // Detener el cronómetro en caso de error
        alert(message);
    }

    // ---------------------------------
    // LÓGICA DEL CRONÓMETRO Y FEEDBACK
    // ---------------------------------
    
    function startTimer() {
        // Reinicia el cronómetro del frontend (mide el tiempo total de red + servidor)
        startTime = performance.now(); 
        processInfo.style.display = 'flex'; // Hace visible el contenedor del tiempo/carga
        loading.style.display = 'inline';
        timerDisplay.textContent = '0.00 ms';
        timerDisplay.style.color = 'var(--color-accent-blue)'; 

        // Muestra el tiempo transcurrido en el frontend cada 50ms
        timerInterval = setInterval(() => {
            const elapsedTime = performance.now() - startTime;
            timerDisplay.textContent = `${elapsedTime.toFixed(2)} ms`;
        }, 50) as unknown as number; 
    }

    function stopTimer(serverLatencyMs?: number) {
        clearInterval(timerInterval);
        timerInterval = undefined;
        loading.style.display = 'none';

        if (serverLatencyMs !== undefined) {
            // Muestra la latencia EXACTA de Rust/Ruby que viene del servidor
            timerDisplay.textContent = `Rust: ${serverLatencyMs.toFixed(2)} ms`;
            timerDisplay.style.color = 'var(--color-primary-green)'; // Éxito en verde
        } else {
            // Si se detiene por error
            timerDisplay.textContent = 'Finalizado'; 
            timerDisplay.style.color = 'var(--color-accent-red)';
        }
    }
    
    // ---------------------------------
    // A. Lógica del Slider 
    // ---------------------------------
    if (slider) {
        slider.addEventListener('input', () => {
            const value = parseInt(slider.value, 10);
            rangeValueDisplay.textContent = value.toString();

            // Transición de color del fondo (0-20 Azul Océano, 21-40 Rojo Intenso)
            if (value >= 0 && value <= 20) {
                body.classList.remove('bg-red-20-40');
                body.classList.add('bg-blue-0-20');
            } else if (value > 20 && value <= 40) {
                body.classList.remove('bg-blue-0-20');
                body.classList.add('bg-red-20-40');
            }
        });
    }

    // ---------------------------------
    // B. Lógica de Generación de Texto (Llamada al Servidor Seguro)
    // ---------------------------------
    if (characterOptions) {
        characterOptions.addEventListener('click', async (e) => {
            const target = e.target as HTMLButtonElement;
            if (target.tagName === 'BUTTON' && target.dataset.chars) {
                const chars = target.dataset.chars;

                output.value = '';
                
                startTimer(); // <<< INICIAR EL CRONÓMETRO >>>

                try {
                    const response = await fetch('/generar_texto', {
                        method: 'POST',
                        headers: { 
                            'Content-Type': 'application/json',
                            // Enviar el token CSRF para pasar el chequeo de seguridad
                            'X-CSRF-Token': csrfToken
                        },
                        body: JSON.stringify({ chars })
                    });
                    
                    const data = await response.json();

                    if (!response.ok) {
                        displayError(data.error || `Error ${response.status}: Error de servidor.`);
                        return;
                    }
                    
                    // Detener el cronómetro y mostrar el tiempo de Rust (data.latency)
                    stopTimer(data.latency); 

                    output.value = data.text;

                } catch (error) {
                    displayError('Error de red al conectar con el servidor.');
                } finally {

                }
            }
        });
    }

    // ---------------------------------
    // C. Copiar Texto
    // ---------------------------------
    if (copyButton) {
        copyButton.addEventListener('click', () => {
            if (output.value) {
                navigator.clipboard.writeText(output.value)
                    .then(() => {
                        copyButton.textContent = '✅ ¡Copiado!';
                        setTimeout(() => {
                            copyButton.textContent = 'Copiar Texto (Clipboard)';
                        }, 1500);
                    })
                    .catch(() => alert('Error al copiar.'));
            }
        });
    }
});