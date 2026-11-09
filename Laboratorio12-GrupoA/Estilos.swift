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

// MARK: - Formato

enum Formato {
    private static let numero: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    /// 1234.5 → "S/ 1,234.50"
    static func soles(_ valor: Double) -> String {
        "S/ " + (numero.string(from: NSNumber(value: valor)) ?? "0.00")
    }

    /// "Laptop Pro 14" → "LP"; "Monitor" → "MO"
    static func iniciales(_ texto: String) -> String {
        let palabras = texto.split(separator: " ").filter { $0.first?.isLetter == true }
        if palabras.count >= 2 {
            return (String(palabras[0].prefix(1)) + String(palabras[1].prefix(1))).uppercased()
        }
        return String((palabras.first ?? Substring(texto)).prefix(2)).uppercased()
    }
}

extension Estilo {
    /// Stock: verde más de 10, ámbar de 6 a 10, rojo 5 o menos.
    static func colorStock(_ stock: Int64) -> UIColor {
        if stock > 10 { return .systemGreen }
        if stock >= 6 { return .systemOrange }
        return .systemRed
    }

    /// Color estable para el avatar según el texto.
    static func colorAvatar(_ texto: String) -> UIColor {
        let paleta: [UIColor] = [.systemBlue, .systemPurple, .systemTeal, .systemIndigo, .systemPink, .systemGreen]
        let suma = texto.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return paleta[suma % paleta.count]
    }
}

// MARK: - Avatar con iniciales

final class AvatarIniciales: UILabel {
    init(tamano: CGFloat = 40) {
        super.init(frame: .zero)
        font = .systemFont(ofSize: 15, weight: .bold)
        textColor = .white
        textAlignment = .center
        layer.cornerRadius = 10
        layer.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: tamano).isActive = true
        heightAnchor.constraint(equalToConstant: tamano).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    func configurar(_ texto: String, color: UIColor? = nil) {
        text = Formato.iniciales(texto)
        backgroundColor = color ?? Estilo.colorAvatar(texto)
    }
}

// MARK: - Pastilla (etiqueta con fondo de color)

final class Pastilla: UILabel {
    private let relleno = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

    init() {
        super.init(frame: .zero)
        font = .systemFont(ofSize: 12, weight: .semibold)
        textColor = .white
        textAlignment = .center
        layer.masksToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    func configurar(_ texto: String, color: UIColor) {
        text = texto
        backgroundColor = color
    }

    override var intrinsicContentSize: CGSize {
        let base = super.intrinsicContentSize
        return CGSize(width: base.width + relleno.left + relleno.right,
                      height: base.height + relleno.top + relleno.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: relleno))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

// MARK: - Chips de filtro (selección única)

final class BarraChips: UIScrollView {
    var alSeleccionar: ((Int) -> Void)?
    private(set) var seleccionado = 0
    private let pila = UIStackView()
    private var botones: [UIButton] = []

    init() {
        super.init(frame: .zero)
        showsHorizontalScrollIndicator = false
        pila.axis = .horizontal
        pila.spacing = 8
        pila.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pila)
        NSLayoutConstraint.activate([
            pila.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            pila.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            pila.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: 16),
            pila.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor, constant: -16),
            pila.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    func configurar(_ titulos: [String], seleccionado indice: Int = 0) {
        botones.forEach { $0.removeFromSuperview() }
        botones = titulos.enumerated().map { indice, titulo in
            let boton = UIButton(configuration: .filled())
            boton.tag = indice
            boton.accessibilityIdentifier = "chip_" + titulo
            boton.configuration?.title = titulo
            boton.addTarget(self, action: #selector(tocar(_:)), for: .touchUpInside)
            pila.addArrangedSubview(boton)
            return boton
        }
        seleccionar(min(indice, max(titulos.count - 1, 0)))
    }

    private func seleccionar(_ indice: Int) {
        seleccionado = indice
        for boton in botones {
            let activo = boton.tag == indice
            var config = boton.configuration ?? .filled()
            config.cornerStyle = .capsule
            config.baseBackgroundColor = activo ? .systemBlue : .secondarySystemGroupedBackground
            config.baseForegroundColor = activo ? .white : .label
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
            boton.configuration = config
            boton.isSelected = activo
        }
    }

    @objc private func tocar(_ boton: UIButton) {
        seleccionar(boton.tag)
        alSeleccionar?(boton.tag)
    }
}
