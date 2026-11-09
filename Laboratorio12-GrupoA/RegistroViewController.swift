//
//  RegistroViewController.swift
//  Laboratorio12-GrupoA
//
//  A2 · Crear cuenta: nombre completo, usuario único (con aviso si ya
//  existe), clave mínimo 6 y su confirmación, rol y botón Registrarme.
//  Al registrarse entra directo a la app.
//

import UIKit
import CoreData

final class RegistroViewController: UIViewController {

    private let campoNombre = CampoTarjeta(titulo: "Nombre completo")
    private let campoUsuario = CampoTarjeta(titulo: "Usuario")
    private let campoClave = CampoTarjeta(titulo: "Clave (mínimo 6 caracteres)", seguro: true)
    private let campoConfirmar = CampoTarjeta(titulo: "Confirmar clave", seguro: true)
    private let selectorRol = UISegmentedControl(items: [Rol.vendedor, Rol.supervisor])

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Crear cuenta"
        view.backgroundColor = .systemGroupedBackground
        construirInterfaz()
    }

    // MARK: - Interfaz

    private func construirInterfaz() {
        campoNombre.campo.autocapitalizationType = .words
        campoUsuario.campo.addTarget(self, action: #selector(revisarDisponibilidad), for: .editingChanged)

        let etiquetaRol = UILabel()
        etiquetaRol.text = "TU ROL"
        etiquetaRol.font = .systemFont(ofSize: 12, weight: .semibold)
        etiquetaRol.textColor = .secondaryLabel
        selectorRol.selectedSegmentIndex = 0

        let botonRegistrar = Estilo.botonPrincipal("Registrarme")
        botonRegistrar.addTarget(self, action: #selector(registrar), for: .touchUpInside)

        let nota = UILabel()
        nota.text = "Al registrarte entrarás directamente a la app con las pestañas de tu rol."
        nota.font = .systemFont(ofSize: 13)
        nota.textColor = .secondaryLabel
        nota.textAlignment = .center
        nota.numberOfLines = 0

        let formulario = UIStackView(arrangedSubviews: [
            campoNombre, campoUsuario, campoClave, campoConfirmar,
            etiquetaRol, selectorRol, botonRegistrar, nota
        ])
        formulario.axis = .vertical
        formulario.spacing = 14
        formulario.setCustomSpacing(20, after: campoConfirmar)
        formulario.setCustomSpacing(8, after: etiquetaRol)
        formulario.setCustomSpacing(24, after: selectorRol)

        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        formulario.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(formulario)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            formulario.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            formulario.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            formulario.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            formulario.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Usuario único

    /// Pista del docente: fetch con NSPredicate "usuario ==[c] %@" y ver si devuelve resultados.
    private func existeUsuario(_ usuario: String) -> Bool {
        let pedido = Usuario.fetchRequest()
        pedido.predicate = NSPredicate(format: "usuario ==[c] %@", usuario)
        pedido.fetchLimit = 1
        let resultados = (try? AppDelegate.contexto.fetch(pedido)) ?? []
        return !resultados.isEmpty
    }

    @objc private func revisarDisponibilidad() {
        let usuario = campoUsuario.texto
        guard !usuario.isEmpty else {
            campoUsuario.estado.isHidden = true
            return
        }
        if existeUsuario(usuario) {
            campoUsuario.estado.text = "✗ Ya existe"
            campoUsuario.estado.textColor = .systemRed
        } else {
            campoUsuario.estado.text = "✓ Disponible"
            campoUsuario.estado.textColor = .systemGreen
        }
        campoUsuario.estado.isHidden = false
    }

    // MARK: - Registrar

    @objc private func registrar() {
        view.endEditing(true)
        let nombre = campoNombre.texto
        let usuario = campoUsuario.texto
        let clave = campoClave.campo.text ?? ""
        let confirmacion = campoConfirmar.campo.text ?? ""

        guard !nombre.isEmpty else {
            mostrarAlerta("Datos incompletos", "Ingresa tu nombre completo.")
            return
        }
        guard !usuario.isEmpty else {
            mostrarAlerta("Datos incompletos", "Ingresa un usuario.")
            return
        }
        guard !existeUsuario(usuario) else {
            mostrarAlerta("Usuario no disponible", "El usuario \"\(usuario)\" ya existe. Elige otro.")
            return
        }
        guard clave.count >= 6 else {
            mostrarAlerta("Clave inválida", "La clave debe tener mínimo 6 caracteres.")
            return
        }
        guard clave == confirmacion else {
            mostrarAlerta("Clave inválida", "La clave y su confirmación no coinciden.")
            return
        }

        let contexto = AppDelegate.contexto
        let nuevo = Usuario(context: contexto)
        nuevo.nombre = nombre
        nuevo.usuario = usuario
        nuevo.clave = clave
        nuevo.rol = selectorRol.selectedSegmentIndex == 1 ? Rol.supervisor : Rol.vendedor

        do {
            try contexto.save()
        } catch {
            contexto.rollback()
            mostrarAlerta("Error", "No se pudo crear la cuenta.")
            return
        }

        Sesion.compartida.usuarioActual = nuevo
        sceneDelegate?.mostrarPestanas()
    }
}
