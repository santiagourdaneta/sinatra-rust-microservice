@echo off
title Inicializando Git...

:: Inicializa el repositorio Git
git init

:: Cambia el nombre de la rama a main
git branch -m master main

:: Agrega todos los archivos
git add .

:: Realiza el primer commit
git commit -m "first commit"

:: Pide la URL del repositorio remoto
set /p repo_url=Introduce la URL del repositorio GitHub (ej. https://github.com/usuario/repositorio.git): 

:: Agrega el repositorio remoto
git remote add origin %repo_url%

:: Sincroniza con la rama remota
git pull origin main --allow-unrelated-histories

:: Push al repositorio remoto
git push -u origin main

echo.
echo ✅ Repositorio Git configurado correctamente.
pause
