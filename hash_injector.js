// hash_injector.js

const fs = require('fs');
const crypto = require('crypto');

const filesToHash = [
    {
        original: 'public/script.min.js', 
        templateFile: 'app.rb', 
        templateKey: 'script.5678.min.js'
    }
];

filesToHash.forEach(file => {
    try {
        // 1. Calcular el hash (código único) del contenido del archivo
        const content = fs.readFileSync(file.original);
        const hash = crypto.createHash('md5').update(content).digest('hex').substring(0, 8);
        
        // 2. Definir el nuevo nombre del archivo
        const newName = file.original.replace(/\.min\.js$/, `.${hash}.min.js`);
        
        // 3. Renombrar el archivo físico
        fs.renameSync(file.original, newName);

        // 4. Actualizar la referencia en el archivo Ruby (app.rb)
        let rubyContent = fs.readFileSync(file.templateFile, 'utf8');
        const updatedRubyContent = rubyContent.replace(
            file.templateKey, 
            newName.replace('public/', '/') // Reemplazar la ruta pública por la URL relativa
        );

        // 5. Escribir el cambio en app.rb
        fs.writeFileSync(file.templateFile, updatedRubyContent, 'utf8');

        console.log(`✅ [HASH] ${file.original} -> ${newName}. app.rb actualizado.`);

    } catch (error) {
        console.error(`❌ Error al procesar el archivo: ${file.original}`);
        console.error(error.message);
    }
});