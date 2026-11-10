//
//  ResumenViewController.swift
//  Laboratorio12-GrupoA
//
//  A9 · Resumen (solo supervisor): ① saludo con nombre y rol,
//  ② indicadores con comparación contra el día anterior,
//  ③ gráfico de barras de los últimos 7 días, ④ ranking de vendedores del mes,
//  ⑤ productos con stock bajo. Datos obtenidos con fetch requests
//  (las ventas anuladas no cuentan).
//

import UIKit
import CoreData

final class ResumenViewController: UIViewController {

    private let fecha = UILabel()
    private let saludo = UILabel()
    private let etiquetaRol = Pastilla()
    private let tarjetaHoy = TarjetaIndicador(titulo: "Vendido hoy")
    private let tarjetaIGV = TarjetaIndicador(titulo: "IGV del mes")
    private let grafico = GraficoBarras()
    private let ranking = UIStackView()
    private let stockBajo = UIStackView()

    private static let formatoFecha: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_PE")
        f.dateFormat = "EEEE d 'de' MMMM"
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        construirInterfaz()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        cargarDatos()
    }

    // MARK: - Interfaz

    private func construirInterfaz() {
        fecha.font = .systemFont(ofSize: 14)
        fecha.textColor = .secondaryLabel
        saludo.font = .systemFont(ofSize: 28, weight: .bold)
        etiquetaRol.font = .systemFont(ofSize: 13, weight: .semibold)
        let textosCabecera = UIStackView(arrangedSubviews: [fecha, saludo])
        textosCabecera.axis = .vertical
        let cabecera = UIStackView(arrangedSubviews: [textosCabecera, etiquetaRol])
        cabecera.alignment = .top

        tarjetaHoy.detalle.font = .systemFont(ofSize: 12, weight: .semibold)
        tarjetaIGV.detalle.text = " "
        let indicadores = UIStackView(arrangedSubviews: [tarjetaHoy, tarjetaIGV])
        indicadores.spacing = 12
        indicadores.distribution = .fillEqually

        ranking.axis = .vertical
        ranking.spacing = 10
        stockBajo.axis = .vertical
        stockBajo.spacing = 8

        let contenido = UIStackView(arrangedSubviews: [
            cabecera,
            indicadores,
            tarjeta("Ventas de los últimos 7 días (S/)", grafico),
            tarjeta("Ranking de vendedores (mes)", ranking),
            tarjeta("Stock bajo (≤ 5)", stockBajo)
        ])
        contenido.axis = .vertical
        contenido.spacing = 14

        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        contenido.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(contenido)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contenido.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
            contenido.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            contenido.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            contenido.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16)
        ])
    }

    private func tarjeta(_ titulo: String, _ cuerpo: UIView) -> UIView {
        let etiqueta = UILabel()
        etiqueta.text = titulo
        etiqueta.font = .systemFont(ofSize: 13)
        etiqueta.textColor = .secondaryLabel
        let pila = UIStackView(arrangedSubviews: [etiqueta, cuerpo])
        pila.axis = .vertical
        pila.spacing = 12
        pila.translatesAutoresizingMaskIntoConstraints = false
        let fondo = UIView()
        fondo.backgroundColor = .secondarySystemGroupedBackground
        fondo.layer.cornerRadius = 14
        fondo.addSubview(pila)
        NSLayoutConstraint.activate([
            pila.topAnchor.constraint(equalTo: fondo.topAnchor, constant: 14),
            pila.bottomAnchor.constraint(equalTo: fondo.bottomAnchor, constant: -14),
            pila.leadingAnchor.constraint(equalTo: fondo.leadingAnchor, constant: 14),
            pila.trailingAnchor.constraint(equalTo: fondo.trailingAnchor, constant: -14)
        ])
        return fondo
    }

    // MARK: - Datos

    private func cargarDatos() {
        let contexto = AppDelegate.contexto
        let usuario = Sesion.compartida.usuarioActual
        let ahora = Date()

        // ① Saludo
        let textoFecha = Self.formatoFecha.string(from: ahora)
        fecha.text = textoFecha.prefix(1).uppercased() + textoFecha.dropFirst()
        let primerNombre = (usuario?.nombre ?? "").split(separator: " ").first.map(String.init) ?? ""
        saludo.text = "Hola, \(primerNombre)"
        etiquetaRol.configurar(usuario?.rol ?? "", color: .systemPurple)

        // ② Indicadores con comparación contra el día anterior
        let ayer = Calendar.current.date(byAdding: .day, value: -1, to: ahora)!
        let vendidoHoy = ConsultasResumen.vendidoDelDia(ahora, en: contexto)
        let vendidoAyer = ConsultasResumen.vendidoDelDia(ayer, en: contexto)
        tarjetaHoy.monto.text = Formato.soles(vendidoHoy)
        if vendidoAyer > 0 {
            let variacion = (vendidoHoy - vendidoAyer) / vendidoAyer * 100
            let subio = variacion >= 0
            tarjetaHoy.detalle.text = "\(subio ? "▲" : "▼") \(Int(abs(variacion).rounded()))% vs ayer"
            tarjetaHoy.detalle.textColor = subio ? .systemGreen : .systemRed
        } else {
            tarjetaHoy.detalle.text = "Ayer: \(Formato.soles(0))"
            tarjetaHoy.detalle.textColor = .secondaryLabel
        }
        tarjetaHoy.accessibilityLabel = "Vendido hoy"
        tarjetaHoy.accessibilityValue = "\(tarjetaHoy.monto.text ?? "") · \(tarjetaHoy.detalle.text ?? "")"

        tarjetaIGV.monto.text = Formato.soles(ConsultasResumen.igvDelMes(en: contexto, referencia: ahora))
        tarjetaIGV.accessibilityLabel = "IGV del mes"
        tarjetaIGV.accessibilityValue = tarjetaIGV.monto.text

        // ③ Últimos 7 días
        grafico.mostrar(ConsultasResumen.ultimos7Dias(en: contexto, referencia: ahora))

        // ④ Ranking de vendedores del mes
        ranking.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let filas = ConsultasResumen.rankingDelMes(en: contexto, referencia: ahora)
        let maximo = filas.first?.monto ?? 0
        if filas.isEmpty {
            ranking.addArrangedSubview(textoVacio("Sin ventas en el mes"))
        }
        for fila in filas {
            ranking.addArrangedSubview(filaRanking(fila.nombre, fila.monto, maximo: maximo))
        }

        // ⑤ Stock bajo
        stockBajo.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let productos = ConsultasResumen.stockBajo(en: contexto)
        if productos.isEmpty {
            stockBajo.addArrangedSubview(textoVacio("Sin productos con stock bajo"))
        }
        for producto in productos {
            stockBajo.addArrangedSubview(filaStockBajo(producto))
        }
    }

    private func textoVacio(_ texto: String) -> UILabel {
        let etiqueta = UILabel()
        etiqueta.text = texto
        etiqueta.font = .systemFont(ofSize: 14)
        etiqueta.textColor = .secondaryLabel
        return etiqueta
    }

    private func filaRanking(_ nombre: String, _ monto: Double, maximo: Double) -> UIView {
        let texto = NSMutableAttributedString(string: nombre, attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)])
        texto.append(NSAttributedString(string: " · \(Formato.soles(monto))", attributes: [
            .font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.secondaryLabel
        ]))
        let etiqueta = UILabel()
        etiqueta.attributedText = texto
        let barra = UIProgressView(progressViewStyle: .default)
        barra.progress = maximo > 0 ? Float(monto / maximo) : 0
        barra.transform = CGAffineTransform(scaleX: 1, y: 2)
        let pila = UIStackView(arrangedSubviews: [etiqueta, barra])
        pila.axis = .vertical
        pila.spacing = 8
        pila.isAccessibilityElement = true
        pila.accessibilityIdentifier = "ranking"
        pila.accessibilityLabel = "\(nombre) · \(Formato.soles(monto))"
        return pila
    }

    private func filaStockBajo(_ producto: Producto) -> UIView {
        let etiqueta = UILabel()
        etiqueta.text = "\(producto.nombre ?? "") · \(producto.stock) u."
        etiqueta.font = .systemFont(ofSize: 16, weight: .semibold)
        let reponer = Pastilla()
        reponer.configurar("Reponer", color: .systemRed)
        let fila = UIStackView(arrangedSubviews: [etiqueta, reponer])
        fila.alignment = .center
        fila.isAccessibilityElement = true
        fila.accessibilityIdentifier = "stockBajo"
        fila.accessibilityLabel = etiqueta.text
        return fila
    }
}

// MARK: - Gráfico de barras (UIKit, sin SwiftUI)

final class GraficoBarras: UIView {
    private let columnas = UIStackView()
    private let altoMaximo: CGFloat = 110
    private static let inicialDia = ["D", "L", "M", "X", "J", "V", "S"]   // weekday 1 = domingo

    override init(frame: CGRect) {
        super.init(frame: frame)
        columnas.distribution = .fillEqually
        columnas.spacing = 10
        columnas.alignment = .bottom
        columnas.translatesAutoresizingMaskIntoConstraints = false
        addSubview(columnas)
        NSLayoutConstraint.activate([
            columnas.topAnchor.constraint(equalTo: topAnchor),
            columnas.bottomAnchor.constraint(equalTo: bottomAnchor),
            columnas.leadingAnchor.constraint(equalTo: leadingAnchor),
            columnas.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    func mostrar(_ datos: [(dia: Date, monto: Double)]) {
        columnas.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let maximo = datos.map(\.monto).max() ?? 0
        let calendario = Calendar.current

        for (indice, dato) in datos.enumerated() {
            let esHoy = indice == datos.count - 1
            let barra = UIView()
            barra.backgroundColor = esHoy ? .systemBlue : .systemBlue.withAlphaComponent(0.18)
            barra.layer.cornerRadius = 4
            barra.translatesAutoresizingMaskIntoConstraints = false
            let alto = maximo > 0 ? max(CGFloat(dato.monto / maximo) * altoMaximo, 2) : 2

            let contenedor = UIView()
            contenedor.translatesAutoresizingMaskIntoConstraints = false
            contenedor.addSubview(barra)
            NSLayoutConstraint.activate([
                contenedor.heightAnchor.constraint(equalToConstant: altoMaximo),
                barra.leadingAnchor.constraint(equalTo: contenedor.leadingAnchor),
                barra.trailingAnchor.constraint(equalTo: contenedor.trailingAnchor),
                barra.bottomAnchor.constraint(equalTo: contenedor.bottomAnchor),
                barra.heightAnchor.constraint(equalToConstant: alto)
            ])

            let dia = UILabel()
            dia.text = Self.inicialDia[calendario.component(.weekday, from: dato.dia) - 1]
            dia.font = .systemFont(ofSize: 11)
            dia.textColor = .secondaryLabel
            dia.textAlignment = .center

            let columna = UIStackView(arrangedSubviews: [contenedor, dia])
            columna.axis = .vertical
            columna.spacing = 6
            columna.isAccessibilityElement = true
            columna.accessibilityIdentifier = "barra_\(indice)"
            columna.accessibilityLabel = "\(dia.text ?? "") \(calendario.component(.day, from: dato.dia))"
            columna.accessibilityValue = Formato.soles(dato.monto)
            columnas.addArrangedSubview(columna)
        }
    }
}
