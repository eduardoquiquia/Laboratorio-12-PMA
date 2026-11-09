//
//  Estilos.swift
//  Laboratorio12-GrupoA
//
//  Componentes visuales comunes a las pantallas.
//

import UIKit

enum Estilo {
    /// Botón azul principal (Ingresar, Registrarme, Registrar venta).
    static func botonPrincipal(_ titulo: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = titulo
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { atributos in
            var atributos = atributos
            atributos.font = .systemFont(ofSize: 17, weight: .semibold)
            return atributos
        }
        let boton = UIButton(configuration: config)
        boton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return boton
    }
}

/// Tarjeta blanca con un título pequeño en mayúsculas y un campo de texto (A1, A2).
final class CampoTarjeta: UIView {
    let titulo = UILabel()
    let campo = UITextField()
    /// Texto opcional a la derecha del campo (por ejemplo "✓ Disponible").
    let estado = UILabel()

    init(titulo texto: String, seguro: Bool = false) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 12

        titulo.text = texto.uppercased()
        titulo.font = .systemFont(ofSize: 11, weight: .semibold)
        titulo.textColor = .secondaryLabel

        campo.font = .systemFont(ofSize: 17)
        campo.autocorrectionType = .no
        campo.autocapitalizationType = .none
        campo.isSecureTextEntry = seguro
        if seguro {
            // Evita la sugerencia de "contraseña segura" del sistema.
            campo.textContentType = .oneTimeCode
        }

        estado.font = .systemFont(ofSize: 13)
        estado.isHidden = true
        estado.setContentHuggingPriority(.required, for: .horizontal)
        estado.setContentCompressionResistancePriority(.required, for: .horizontal)

        let fila = UIStackView(arrangedSubviews: [campo, estado])
        fila.spacing = 8
        let pila = UIStackView(arrangedSubviews: [titulo, fila])
        pila.axis = .vertical
        pila.spacing = 4
        pila.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pila)
        NSLayoutConstraint.activate([
            pila.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            pila.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            pila.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            pila.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(enfocar)))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    /// Texto sin espacios al inicio ni al final.
    var texto: String {
        (campo.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @objc private func enfocar() {
        campo.becomeFirstResponder()
    }
}

extension UIViewController {
    func mostrarAlerta(_ titulo: String, _ mensaje: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alerta, animated: true)
    }

    var sceneDelegate: SceneDelegate? {
        (view.window?.windowScene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .delegate as? SceneDelegate
    }
}
