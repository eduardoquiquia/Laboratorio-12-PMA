//
//  VentaCelda.swift
//  Laboratorio12-GrupoA
//
//  Fila de una venta: cliente, fecha · producto × cantidad (o vendedor ·
//  producto × cantidad) y total. Si está anulada se muestra tachada y con
//  la etiqueta "Anulada".
//

import UIKit

final class VentaCelda: UITableViewCell {
    static let id = "VentaCelda"

    /// Cómo se identifica la fila a la izquierda.
    enum Modo {
        /// A6: ícono de estado (✓ válida, ✕ anulada) y "dd/MM · Producto × n".
        case estado
        /// A7: iniciales del cliente y "Vendedor · Producto × n" (relación venta ▶ vendedor).
        case conVendedor
    }

    private let icono = AvatarIniciales()
    private let cliente = UILabel()
    private let detalle = UILabel()
    private let total = UILabel()
    private let etiquetaAnulada = Pastilla()

    private static let fecha: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM"
        return f
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        cliente.font = .systemFont(ofSize: 16, weight: .semibold)
        detalle.font = .systemFont(ofSize: 13)
        detalle.textColor = .secondaryLabel
        total.font = .systemFont(ofSize: 15, weight: .semibold)
        total.setContentHuggingPriority(.required, for: .horizontal)
        total.setContentCompressionResistancePriority(.required, for: .horizontal)
        etiquetaAnulada.configurar("Anulada", color: .systemRed)

        let contenedorEtiqueta = UIStackView(arrangedSubviews: [etiquetaAnulada, UIView()])
        let textos = UIStackView(arrangedSubviews: [cliente, detalle, contenedorEtiqueta])
        textos.axis = .vertical
        textos.spacing = 2
        let fila = UIStackView(arrangedSubviews: [icono, textos, total])
        fila.alignment = .center
        fila.spacing = 12
        fila.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fila)
        NSLayoutConstraint.activate([
            fila.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            fila.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            fila.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            fila.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    func configurar(_ venta: Venta, modo: Modo) {
        let nombreCliente = venta.cliente?.nombre ?? ""
        let producto = (venta.producto?.nombre ?? "").split(separator: " ").first.map(String.init) ?? ""
        let cantidad = "\(producto) × \(venta.cantidad)"

        switch modo {
        case .estado:
            icono.text = venta.anulada ? "✕" : "✓"
            icono.backgroundColor = venta.anulada ? .systemRed.withAlphaComponent(0.55) : .systemGreen
            let dia = venta.fecha.map { Self.fecha.string(from: $0) } ?? ""
            detalle.text = "\(dia) · \(cantidad)"
        case .conVendedor:
            icono.configurar(nombreCliente)
            // Nombre del vendedor leído de la relación venta ▶ vendedor.
            let vendedor = (venta.vendedor?.nombre ?? "").split(separator: " ").first.map(String.init) ?? ""
            detalle.text = "\(vendedor) · \(cantidad)"
        }

        let textoTotal = Formato.soles(venta.total)
        if venta.anulada {
            let tachado: [NSAttributedString.Key: Any] = [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.secondaryLabel
            ]
            cliente.attributedText = NSAttributedString(string: nombreCliente, attributes: tachado)
            total.attributedText = NSAttributedString(string: textoTotal, attributes: tachado)
        } else {
            cliente.attributedText = NSAttributedString(string: nombreCliente, attributes: [.foregroundColor: UIColor.label])
            total.attributedText = NSAttributedString(string: textoTotal, attributes: [.foregroundColor: UIColor.label])
        }
        etiquetaAnulada.superview?.isHidden = !venta.anulada
        accessibilityValue = venta.anulada ? "Anulada" : nil
    }
}
