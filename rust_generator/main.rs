use std::env;
use std::process;
use rand::seq::SliceRandom;

fn main() {
    // 1. Leer el argumento (el número de caracteres deseado)
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
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

    // 2. Definir "frases semilla" sobre el calentamiento global
    // Usamos frases cortas para que la memoria sea ligera.
    let seeds = vec![
        "El aumento de la temperatura global.",
        "La quema de combustibles fósiles es la causa principal.",
        "Se necesitan energías renovables como la solar y eólica.",
        "El derretimiento de los casquetes polares sube el nivel del mar.",
        "Adoptar prácticas de consumo responsable.",
        "Impacto en ecosistemas y biodiversidad.",
        "La descarbonización es una prioridad climática mundial.",
    ];

    // 3. Generar el texto hasta alcanzar el límite de caracteres
    let mut generated_text = String::new();

    while generated_text.len() < char_count {
        // Escoger una frase aleatoriamente y añadirla
        if let Some(phrase) = seeds.choose(&mut rand::thread_rng()) {
            generated_text.push_str(phrase);
            generated_text.push_str(" "); // Añadir espacio
        }

        // Cortar el texto exactamente al tamaño pedido
        if generated_text.len() > char_count {
            generated_text.truncate(char_count);
        }
    }

    // 4. Imprimir el texto generado al 'stdout' (la terminal)
    // El servidor Ruby capturará este texto.
    println!("{}", generated_text);
}