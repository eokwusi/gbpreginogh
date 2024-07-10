# Deployment


# A tener en cuenta...

- Oryx no elimina código eliminado del repositorio en wwwroot


# Cookbook


### Azure - Linux

- Podemos definir la versión de Composer que se ejecuta al desplegar la webapp estableciendo la variable de entorno "PHP_COMPOSER_VERSION"
  Versiones soportadas (desde oryx):

    ```
    1.10.0, 1.10.1, 1.10.10, 1.10.11, 1.10.12, 1.10.13, 1.10.14, 1.10.15, 1.10.16, 1.10.17, 1.10.18, 1.10.19, 1.10.2, 1.10.4, 1.10.5, 1.10.6, 1.10.7, 1.10.8, 1.10.9, 1.9.2, 1.9.3, 2.0.0, 2.0.1, 2.0.2, 2.0.3, 2.0.4, 2.0.5, 2.0.6, 2.0.7, 2.0.8, 2.2.9, 2.3.4
    ```

- NPM_RUN_SCRIPT: Variable que establece el nombre del script a ejecutar en la raíz del proyecto. Previamente si esta variables está definida instala dependencias desde package.json