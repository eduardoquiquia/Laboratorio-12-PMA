//
//  ViewController.swift
//  Laboratorio12-GrupoA
//
//  Created by Tecsup on 9/11/26.
//
//  A1 · Login: logo y nombre, usuario, clave oculta, mensaje de error
//  genérico, botón Ingresar y acceso a Crear cuenta.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    private let campoUsuario = CampoTarjeta(titulo: "Usuario")
    private let campoClave = CampoTarjeta(titulo: "Clave", seguro: true)
    private let mensajeError = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.backButtonTitle = "Ingresar"
        construirInterfaz()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Interfaz

    private func construirInterfaz() {
        // ① Logo y nombre
        let logo = UIView()
        logo.backgroundColor = .systemBlue
        logo.layer.cornerRadius = 24
        let carrito = UIImageView(image: UIImage(systemName: "cart.fill"))
        carrito.tintColor = .white
        carrito.contentMode = .scaleAspectFit
        carrito.translatesAutoresizingMaskIntoConstraints = false
        logo.addSubview(carrito)
        logo.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logo.widthAnchor.constraint(equalToConstant: 100),
            logo.heightAnchor.constraint(equalToConstant: 100),
            carrito.centerXAnchor.constraint(equalTo: logo.centerXAnchor),
            carrito.centerYAnchor.constraint(equalTo: logo.centerYAnchor),
            carrito.widthAnchor.constraint(equalToConstant: 56),
            carrito.heightAnchor.constraint(equalToConstant: 56)
        ])

        let nombreApp = UILabel()
        nombreApp.text = "Ventas Tecsup"
        nombreApp.font = .systemFont(ofSize: 30, weight: .bold)
        let subtitulo = UILabel()
        subtitulo.text = "Inicia sesión para continuar"
        subtitulo.font = .systemFont(ofSize: 15)
        subtitulo.textColor = .secondaryLabel

        let cabecera = UIStackView(arrangedSubviews: [logo, nombreApp, subtitulo])
        cabecera.axis = .vertical
        cabecera.alignment = .center
        cabecera.spacing = 10
        cabecera.setCustomSpacing(20, after: logo)

        // ② Usuario · ③ Clave oculta
        campoUsuario.campo.returnKeyType = .next
        campoUsuario.campo.delegate = self
        campoClave.campo.returnKeyType = .go
        campoClave.campo.delegate = self
        campoUsuario.campo.addTarget(self, action: #selector(ocultarError), for: .editingChanged)
        campoClave.campo.addTarget(self, action: #selector(ocultarError), for: .editingChanged)

        // ④ Mensaje de error genérico
        let texto = NSMutableAttributedString(attachment: NSTextAttachment(
            image: UIImage(systemName: "exclamationmark.triangle.fill")!.withTintColor(.systemRed)))
        texto.append(NSAttributedString(string: " Usuario o clave incorrectos"))
        mensajeError.attributedText = texto
        mensajeError.font = .systemFont(ofSize: 14)
        mensajeError.textColor = .systemRed
        mensajeError.isHidden = true

        // ⑤ Ingresar
        let botonIngresar = Estilo.botonPrincipal("Ingresar")
        botonIngresar.addTarget(self, action: #selector(ingresar), for: .touchUpInside)

        // Ⓐ Crear cuenta
        let pregunta = UILabel()
        pregunta.text = "¿Primera vez?"
        pregunta.font = .systemFont(ofSize: 15)
        pregunta.textColor = .secondaryLabel
        let botonCrear = UIButton(type: .system)
        botonCrear.setTitle("Crear cuenta", for: .normal)
        botonCrear.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        botonCrear.addTarget(self, action: #selector(irARegistro), for: .touchUpInside)
        let filaCrear = UIStackView(arrangedSubviews: [pregunta, botonCrear])
        filaCrear.spacing = 4
        let contenedorCrear = UIStackView(arrangedSubviews: [filaCrear])
        contenedorCrear.axis = .vertical
        contenedorCrear.alignment = .center

        let formulario = UIStackView(arrangedSubviews: [
            cabecera, campoUsuario, campoClave, mensajeError, botonIngresar, contenedorCrear
        ])
        formulario.axis = .vertical
        formulario.spacing = 14
        formulario.setCustomSpacing(36, after: cabecera)
        formulario.setCustomSpacing(20, after: mensajeError)

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
            formulario.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 70),
            formulario.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            formulario.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            formulario.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Acciones

    @objc private func ocultarError() {
        mensajeError.isHidden = true
    }

    @objc private func ingresar() {
        view.endEditing(true)
        let usuario = campoUsuario.texto
        let clave = campoClave.campo.text ?? ""

        let pedido = Usuario.fetchRequest()
        pedido.predicate = NSPredicate(format: "usuario ==[c] %@ AND clave == %@", usuario, clave)
        pedido.fetchLimit = 1

        guard !usuario.isEmpty, !clave.isEmpty,
              let encontrado = try? AppDelegate.contexto.fetch(pedido).first else {
            mensajeError.isHidden = false
            return
        }

        mensajeError.isHidden = true
        campoClave.campo.text = ""
        Sesion.compartida.usuarioActual = encontrado
        sceneDelegate?.mostrarPestanas()
    }

    @objc private func irARegistro() {
        navigationController?.pushViewController(RegistroViewController(), animated: true)
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === campoUsuario.campo {
            campoClave.campo.becomeFirstResponder()
        } else {
            ingresar()
        }
        return true
    }
}
