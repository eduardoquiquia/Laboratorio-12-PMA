//
//  NuevaVentaViewController.swift
//  Laboratorio12-GrupoA
//
//  A5 · Nueva venta: ① vendedor de la sesión (automático, no editable),
//  ② cliente, ③ producto, ④ cantidad con stepper y stock disponible,
//  ⑤ resumen calculado (subtotal, descuento, IGV, total), Ⓐ Registrar venta.
//

import UIKit
import CoreData

final class NuevaVentaViewController: UITableViewController {

    private enum Seccion: Int, CaseIterable { case vendedor, datos, resumen }

    private var cliente: Cliente?
    private var producto: Producto?
    private var cantidad: Int64 = 1

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Nueva venta"   // la pestaña conserva "Venta"
        tableView.register(VendedorSesionCelda.self, forCellReuseIdentifier: VendedorSesionCelda.id)
        tableView.register(CantidadCelda.self, forCellReuseIdentifier: CantidadCelda.id)

        let pie = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 84))
        let boton = Estilo.botonPrincipal("Registrar venta")
        boton.addTarget(self, action: #selector(registrarVenta), for: .touchUpInside)
        boton.translatesAutoresizingMaskIntoConstraints = false
        pie.addSubview(boton)
        NSLayoutConstraint.activate([
            boton.topAnchor.constraint(equalTo: pie.topAnchor, constant: 16),
            boton.leadingAnchor.constraint(equalTo: pie.leadingAnchor, constant: 20),
            boton.trailingAnchor.constraint(equalTo: pie.trailingAnchor, constant: -20)
        ])
        tableView.tableFooterView = pie
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private var calculo: CalculoVenta {
        CalculoVenta(cantidad: producto == nil ? 0 : cantidad,
                     precioUnitario: producto?.precio ?? 0,
                     categoria: cliente?.categoriaCalculada ?? .regular)
    }

    // MARK: - Tabla

    override func numberOfSections(in tableView: UITableView) -> Int { Seccion.allCases.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Seccion(rawValue: section)! {
        case .vendedor: return 1
        case .datos: return 3
        case .resumen: return 4
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Seccion(rawValue: section) == .resumen ? "Resumen (calculado)" : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Seccion(rawValue: indexPath.section)! {
        case .vendedor:
            let celda = tableView.dequeueReusableCell(withIdentifier: VendedorSesionCelda.id, for: indexPath) as! VendedorSesionCelda
            celda.configurar(Sesion.compartida.usuarioActual)
            return celda

        case .datos:
            if indexPath.row == 2 {
                let celda = tableView.dequeueReusableCell(withIdentifier: CantidadCelda.id, for: indexPath) as! CantidadCelda
                celda.configurar(cantidad: cantidad, stock: producto?.stock)
                celda.alCambiar = { [weak self] valor in
                    self?.cantidad = valor
                    self?.tableView.reloadSections(IndexSet(integer: Seccion.resumen.rawValue), with: .none)
                }
                return celda
            }
            let celda = UITableViewCell(style: .value1, reuseIdentifier: nil)
            celda.accessoryType = .disclosureIndicator
            if indexPath.row == 0 {
                celda.textLabel?.text = "Cliente"
                celda.detailTextLabel?.text = cliente?.nombre ?? "Seleccionar"
            } else {
                celda.textLabel?.text = "Producto"
                celda.detailTextLabel?.text = producto?.nombre ?? "Seleccionar"
            }
            return celda

        case .resumen:
            let celda = UITableViewCell(style: .value1, reuseIdentifier: nil)
            celda.selectionStyle = .none
            let c = calculo
            switch indexPath.row {
            case 0:
                celda.textLabel?.text = "Subtotal"
                celda.detailTextLabel?.text = Formato.soles(c.subtotal)
            case 1:
                let esVIP = cliente?.categoriaCalculada == .vip
                celda.textLabel?.text = esVIP ? "Descuento VIP 10%" : "Descuento"
                celda.detailTextLabel?.text = "− " + Formato.soles(c.descuento)
            case 2:
                celda.textLabel?.text = "IGV 18%"
                celda.detailTextLabel?.text = Formato.soles(c.igv)
            default:
                celda.textLabel?.text = "Total"
                celda.textLabel?.font = .systemFont(ofSize: 17, weight: .bold)
                celda.detailTextLabel?.text = Formato.soles(c.total)
                celda.detailTextLabel?.font = .systemFont(ofSize: 17, weight: .bold)
                celda.detailTextLabel?.textColor = .label
            }
            return celda
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Seccion(rawValue: indexPath.section) == .datos else { return }
        if indexPath.row == 0 {
            elegirCliente()
        } else if indexPath.row == 1 {
            elegirProducto()
        }
    }

    // MARK: - Selección

    private func elegirCliente() {
        let pedido = Cliente.fetchRequest()
        pedido.sortDescriptors = [NSSortDescriptor(key: "nombre", ascending: true,
                                                   selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        let clientes = (try? AppDelegate.contexto.fetch(pedido)) ?? []
        let lista = SeleccionViewController(
            titulo: "Cliente",
            opciones: clientes.map { ($0.nombre ?? "", "\($0.documento ?? "") · \($0.categoriaCalculada.rawValue)") }
        ) { [weak self] indice in
            self?.cliente = clientes[indice]
            self?.tableView.reloadData()
        }
        navigationController?.pushViewController(lista, animated: true)
    }

    private func elegirProducto() {
        let pedido = Producto.fetchRequest()
        pedido.sortDescriptors = [NSSortDescriptor(key: "nombre", ascending: true,
                                                   selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        let productos = (try? AppDelegate.contexto.fetch(pedido)) ?? []
        let lista = SeleccionViewController(
            titulo: "Producto",
            opciones: productos.map { ($0.nombre ?? "", "\(Formato.soles($0.precio)) · stock \($0.stock)") }
        ) { [weak self] indice in
            self?.producto = productos[indice]
            self?.tableView.reloadData()
        }
        navigationController?.pushViewController(lista, animated: true)
    }

    // MARK: - Registrar

    @objc private func registrarVenta() {
        guard let vendedor = Sesion.compartida.usuarioActual else { return }
        guard let cliente else {
            mostrarAlerta("Falta el cliente", "Selecciona el cliente de la venta.")
            return
        }
        guard let producto else {
            mostrarAlerta("Falta el producto", "Selecciona el producto de la venta.")
            return
        }

        do {
            let venta = try OperacionesVenta.registrar(cantidad: cantidad, producto: producto, cliente: cliente,
                                                       vendedor: vendedor, en: AppDelegate.contexto)
            let alerta = UIAlertController(
                title: "Venta registrada",
                message: "\(cliente.nombre ?? "") · \(producto.nombre ?? "") × \(venta.cantidad)\nTotal \(Formato.soles(venta.total))",
                preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                self?.reiniciar()
            })
            present(alerta, animated: true)
        } catch ErrorVenta.stockInsuficiente(let disponible) {
            mostrarAlerta("Stock insuficiente",
                          "Solo hay \(disponible) unidades de \(producto.nombre ?? "este producto"). La venta no se registró.")
        } catch {
            mostrarAlerta("Error", "No se pudo registrar la venta.")
        }
    }

    private func reiniciar() {
        cliente = nil
        producto = nil
        cantidad = 1
        tableView.reloadData()
    }
}

// MARK: - Celdas

/// ① Vendedor de la sesión: solo lectura.
final class VendedorSesionCelda: UITableViewCell {
    static let id = "VendedorSesionCelda"
    private let avatar = AvatarIniciales()
    private let nombre = UILabel()
    private let nota = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        nombre.font = .systemFont(ofSize: 15, weight: .semibold)
        nombre.textColor = .systemBlue
        nota.font = .systemFont(ofSize: 13)
        nota.textColor = .secondaryLabel
        nota.numberOfLines = 0
        nota.text = "Sesión iniciada · la venta se registra a tu nombre"
        let textos = UIStackView(arrangedSubviews: [nombre, nota])
        textos.axis = .vertical
        textos.spacing = 2
        let fila = UIStackView(arrangedSubviews: [avatar, textos])
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

    func configurar(_ usuario: Usuario?) {
        avatar.configurar(usuario?.nombre ?? "", color: .systemBlue)
        nombre.text = "\(usuario?.nombre ?? "") · \(usuario?.rol ?? "")"
    }
}

/// ④ Cantidad con stepper y stock disponible.
final class CantidadCelda: UITableViewCell {
    static let id = "CantidadCelda"
    var alCambiar: ((Int64) -> Void)?
    private let titulo = UILabel()
    private let valor = UILabel()
    private let stepper = UIStepper()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        stepper.minimumValue = 1
        stepper.maximumValue = 999
        stepper.addTarget(self, action: #selector(cambio), for: .valueChanged)
        valor.font = .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        valor.accessibilityIdentifier = "cantidad"
        valor.setContentHuggingPriority(.required, for: .horizontal)
        let fila = UIStackView(arrangedSubviews: [titulo, valor, stepper])
        fila.alignment = .center
        fila.spacing = 12
        fila.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(fila)
        NSLayoutConstraint.activate([
            fila.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            fila.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            fila.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            fila.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    func configurar(cantidad: Int64, stock: Int64?) {
        stepper.value = Double(cantidad)
        valor.text = "\(cantidad)"
        let texto = NSMutableAttributedString(string: "Cantidad ")
        let stockTexto = stock.map { "(stock \($0))" } ?? "(stock —)"
        texto.append(NSAttributedString(string: stockTexto, attributes: [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.secondaryLabel
        ]))
        titulo.attributedText = texto
    }

    @objc private func cambio() {
        let nuevo = Int64(stepper.value)
        valor.text = "\(nuevo)"
        alCambiar?(nuevo)
    }
}
