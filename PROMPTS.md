# PROMPTS.md — Laboratorio 12 · Grupo A · Caso Ventas (UIKit + Core Data)

Registro de los prompts usados con el asistente de IA (Claude Code) durante el desarrollo,
las decisiones tomadas y el resultado de cada etapa.

## 1. Prompt inicial

Se entregó al asistente el documento del laboratorio y un prompt con estas instrucciones:

- Trabajar sobre el proyecto Xcode existente `Laboratorio12-GrupoA` (no crear otro).
- Alcance exclusivo: Grupo A – Caso Ventas (UIKit + Core Data).
- Reglas: no asumir, presentar diagnóstico y plan antes de modificar, esperar aprobación,
  no agregar ni simplificar requisitos, trabajar por etapas pequeñas e informar al final de cada una.
- Modelo de datos: Usuario, Producto, Cliente y Venta con sus atributos, relaciones inversas y Delete Rule Deny.
- Pantallas A1–A9 y pestaña Cuenta; `UITabBarController` con pestañas según el rol;
  sesión con una clase de objeto compartido (`static let`) y el usuario actual.
- Reglas de negocio: categoría del cliente, descuento VIP 10 %, IGV 18 %, control de stock,
  anulación con motivo, visibilidad por rol y borrado bloqueado con alerta.
- Git: commits convencionales en español, sin coautores, sin `git push`, cada commit con aprobación.
- Validación final con los 9 casos de prueba del documento.
- Primera respuesta: solo inspección (estado del proyecto, modelo, storyboard, problemas, etapas, commits y preguntas).

## 2. Decisiones confirmadas por el desarrollador

| # | Pregunta | Respuesta |
|---|----------|-----------|
| 1 | Nivel de entrega | Los tres: Base, Nivel + y Reto |
| 2 | Repositorio Git | El asistente ejecuta `git init` en la carpeta del laboratorio |
| 3 | Relación `Producto.ventas` (Deny) | Sí, porque la pide el documento del Grupo A |
| 4 | Compilar sin cambiar `xcode-select` | Sí, con `DEVELOPER_DIR` |
| 5 | Elementos visibles en las maquetas | Sí, incluirlos |
| 6 | Formularios y selección en A5 | Pantallas propias; listas para elegir cliente y producto |
| 7 | Datos iniciales | Cargar un seed |
| 8 | Gráfico, tipos y codegen | Barras con `UIView`, Integer 64, Class Definition, `anulada` = NO |
| 9–11 | Login, Storyboard y entregables | Guiarse por el documento |
| 12 | Después de registrar una venta | Alerta de confirmación y reinicio del formulario |
| — | Pruebas | "Pruébalo tú a mano": pruebas de interfaz XCUITest en el simulador |

## 3. Prompts por etapa

Después de cada etapa el asistente informó qué se hizo y qué se probó, y pidió aprobación del commit.
Los prompts del desarrollador fueron: **"Sí, empieza"** para iniciar cada etapa y **"Sí, haz el commit"** para aprobarla.

| Etapa | Contenido | Commit |
|-------|-----------|--------|
| 1 | Modelo Core Data (4 entidades, inversas, Deny) y seed | `feat: implementa modelo de datos de ventas con Core Data` |
| 2 | Sesión, Login (A1), Registro (A2), pestañas por rol, Cuenta | `feat: agrega autenticación y sesión por roles` |
| 3 | Productos (A3): búsqueda, chips, stock en color, CRUD supervisor | `feat: implementa registro y gestión de productos` |
| 4 | Clientes (A4): total y categoría calculados, borrado bloqueado | `feat: implementa gestión de clientes con categoría calculada` |
| 5 | Nueva venta (A5): stepper, descuento, IGV, total, stock | `feat: implementa registro de ventas y cálculo de impuestos` |
| 6 | Mis ventas (A6): predicate por vendedor, periodo y cliente | `feat: agrega mis ventas con filtros por periodo y cliente` |
| 7 | Ventas del equipo (A7) y Anular venta (A8) | `feat: agrega anulación de ventas y control de stock` |
| 8 | Resumen del supervisor (A9): KPIs, 7 días, ranking, stock bajo | `feat: implementa panel de resumen del supervisor` |
| 9 | Validación final (23 pruebas), ícono, capturas y este archivo | `docs: agrega ícono, capturas y registro de prompts` |

## 4. Casos de prueba del documento

Ejecutados con XCUITest en el simulador iPhone 17 (iOS 26.3):

| N.º | Caso | Resultado |
|-----|------|-----------|
| 1 | Registrar `lparedes` (Supervisor) e intentar `LPAREDES` | ✅ El primero entra a la app; el segundo se rechaza |
| 2 | Claves distintas o de 4 caracteres | ✅ Mensaje de error; no se crea el usuario |
| 3 | Login con clave incorrecta | ✅ "Usuario o clave incorrectos"; no entra |
| 4 | 2 Laptop a S/ 200 a cliente VIP | ✅ 400.00 · 40.00 · 64.80 · 424.80 · stock 40 → 38 |
| 5 | 3 Mouse a S/ 35 a cliente Regular | ✅ 105.00 · 18.90 · 123.90 |
| 6 | 50 unidades con stock 40 | ✅ Alerta; no se registra; el stock no cambia |
| 7 | Vendedor abre Mis ventas | ✅ Solo sus ventas; ninguna fila permite anular |
| 8 | Anular sin motivo y con motivo | ✅ Sin motivo no se puede; con motivo queda anulada, stock vuelve a 40 y el resumen baja S/ 424.80 |
| 9 | Borrar cliente con ventas | ✅ Se impide y se muestra un mensaje |

## 5. Capturas

La carpeta `Capturas/` contiene las imágenes tomadas en el simulador durante las pruebas:
pantallas A1–A9 y Cuenta (`a3_…`, `a4_…`, `a6_…`, `a7_…`, `a9_…`, `cuenta_…`) y cada caso de prueba (`casoN_…`).
