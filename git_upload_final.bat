@echo off
echo Configurando repositorio...
cd /d C:\Users\Lux\Desktop\app-youtube
git reset
git add .gitignore
git add lib/
git add android/app/src/main/AndroidManifest.xml
git add android/app/build.gradle
git add android/build.gradle
git add android/gradle.properties
git add android/settings.gradle
git add android/gradle/wrapper/gradle-wrapper.properties
git add android/gradle/wrapper/gradle-wrapper.jar
git add pubspec.yaml
git add pubspec.lock
git add analysis_options.yaml
git add README.md
git add LICENSE
git add SECURITY.md
git add DEPLOYMENT.md
git add CONTRIBUTING.md
git add web/
git commit -m "update"
git push origin main
echo ¡Subido exitosamente a GitHub!
pause
