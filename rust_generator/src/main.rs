use std::env;
use std::process;
use rand::seq::SliceRandom; 
use std::io::{self, Write}; // Necesario para la salida estándar limpia

fn main() {
    // 1. Recibir los argumentos
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        // Enviar error a stderr, no a stdout, para no interferir con la salida de texto
        eprintln!("Uso: rust_generator <cantidad_de_caracteres>");
        process::exit(1);
    }

    let char_count: usize = match args[1].parse() {
        Ok(n) => n,
        Err(_) => {
            eprintln!("Error: La cantidad de caracteres debe ser un número válido.");
            process::exit(1);
        }
    };

    // 2. Definir frases semilla sobre el calentamiento global
    let seeds = vec![
        "El aumento de la temperatura global.",
        "La quema de combustibles fósiles es la causa principal de la crisis.",
        "La transición hacia energías renovables es urgente para mitigar el cambio climático.",
        "El derretimiento acelerado de los glaciares y casquetes polares eleva el nivel del mar globalmente.",
        "Adoptar prácticas de consumo responsable reduce la huella de carbono individual y colectiva.",
        "El impacto en los ecosistemas y la biodiversidad amenaza la estabilidad del planeta.",
        "La descarbonización de la economía mundial es una prioridad crítica.",
        "Los fenómenos meteorológicos extremos son cada vez más frecuentes y destructivos.",
        "Es vital proteger los bosques como sumideros naturales de carbono.",
    ];

    // 3. Generar el texto
    let mut generated_text = String::new();

    while generated_text.len() < char_count {
        if let Some(phrase) = seeds.choose(&mut rand::thread_rng()) {
            generated_text.push_str(phrase);
            generated_text.push_str(" "); 
        }

        if generated_text.len() > char_count {
            generated_text.truncate(char_count);
        }
    }

    // 4. Imprimir el texto generado al 'stdout' (limpio, sin saltos de línea extra)
    // El 'flush' asegura que todo el texto se envíe inmediatamente.
    if let Err(e) = io::stdout().write_all(generated_text.as_bytes()) {
        eprintln!("Error al escribir en stdout: {}", e);
    }
    if let Err(e) = io::stdout().flush() {
         eprintln!("Error al vaciar stdout: {}", e);
    }
}