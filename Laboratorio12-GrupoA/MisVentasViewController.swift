//
//  MisVentasViewController.swift
//  Laboratorio12-GrupoA
//
//  A6 · Mis ventas (vendedor): ① indicadores propios hoy y mes,
//  ② segmentado Todas / Hoy / Mes, ③ búsqueda por cliente, ④ venta propia,
//  ⑤ venta anulada (tachada, con etiqueta, sin botón).
//  Solo se ven las ventas del vendedor de la sesión (predicate "vendedor == %@").
//

import UIKit
import CoreData

final class MisVentasViewController: UITableViewController {

    private var ventas: [Venta] = []
    private let buscador = UISearchController(searchResultsController: nil)
    private let segmentado = UISegmentedControl(items: PeriodoVenta.allCases.map(\.titulo))
    private let tarjetaHoy = TarjetaIndicador(titulo: "Hoy")
    private let tarjetaMes = TarjetaIndicador(titulo: "Mes")

    private var vendedor: Usuario? { Sesion.compartida.usuarioActual }

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Mis ventas"

        let iniciales = UILabel()
        iniciales.text = Formato.iniciales(vendedor?.nombre ?? "")
        iniciales.font = .systemFont(ofSize: 15, weight: .semibold)
        iniciales.textColor = .systemBlue
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: iniciales)

        buscador.searchResultsUpdater = self
        buscador.obscuresBackgroundDuringPresentation = false
        buscador.searchBar.placeholder = "Buscar por cliente"
        navigationItem.searchController = buscador
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        segmentado.selectedSegmentIndex = PeriodoVenta.todas.rawValue
        segmentado.addTarget(self, action: #selector(cargarVentas), for: .valueChanged)

        let tarjetas = UIStackView(arrangedSubviews: [tarjetaHoy, tarjetaMes])
        tarjetas.spacing = 12
        tarjetas.distribution = .fillEqually
        let cabecera = UIStackView(arrangedSubviews: [tarjetas, segmentado])
        cabecera.axis = .vertical
        cabecera.spacing = 14
        cabecera.isLayoutMarginsRelativeArrangement = true
        cabecera.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 4, trailing: 20)
        cabecera.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 150)
        tableView.tableHeaderView = cabecera

        tableView.register(VentaCelda.self, forCellReuseIdentifier: VentaCelda.id)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cargarIndicadores()
        cargarVentas()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let cabecera = tableView.tableHeaderView else { return }
        let alto = cabecera.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
        if abs(cabecera.frame.height - alto) > 0.5 {
            cabecera.frame.size = CGSize(width: tableView.bounds.width, height: alto)
            tableView.tableHeaderView = cabecera
        }
    }

    // MARK: - Fetch con predicates

    /// ① Indicadores propios (ventas no anuladas del vendedor de la sesión).
    private func cargarIndicadores() {
        guard let vendedor else { return }
        for (periodo, tarjeta) in [(PeriodoVenta.hoy, tarjetaHoy), (.mes, tarjetaMes)] {
            let pedido = FiltroVentas.pedido(vendedor: vendedor, periodo: periodo, soloNoAnuladas: true)
            let ventas = (try? AppDelegate.contexto.fetch(pedido)) ?? []
            tarjeta.mostrar(monto: ventas.reduce(0) { $0 + $1.total }, cantidad: ventas.count)
        }
    }

    @objc private func cargarVentas() {
        guard let vendedor else { return }
        let periodo = PeriodoVenta(rawValue: segmentado.selectedSegmentIndex) ?? .todas
        let pedido = FiltroVentas.pedido(vendedor: vendedor, periodo: periodo, cliente: buscador.searchBar.text ?? "")
        ventas = (try? AppDelegate.contexto.fetch(pedido)) ?? []
        tableView.reloadData()
    }

    // MARK: - Tabla (sin acciones: el vendedor no anula)

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ventas.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(withIdentifier: VentaCelda.id, for: indexPath) as! VentaCelda
        celda.configurar(ventas[indexPath.row], modo: .estado)
        return celda
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "Solo aparecen las ventas de este vendedor."
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { false }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        nil
    }
}

extension MisVentasViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        cargarVentas()
    }
}

// MARK: - Tarjeta de indicador

/// Tarjeta blanca con título, monto y número de ventas (A6 ①, A9 ②).
final class TarjetaIndicador: UIView {
    private let titulo = UILabel()
    let monto = UILabel()
    let detalle = UILabel()

    init(titulo texto: String) {
        super.init(frame: .zero)
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 14
        titulo.text = texto
        titulo.font = .systemFont(ofSize: 13)
        titulo.textColor = .secondaryLabel
        monto.font = .systemFont(ofSize: 22, weight: .bold)
        monto.adjustsFontSizeToFitWidth = true
        monto.minimumScaleFactor = 0.6
        detalle.font = .systemFont(ofSize: 12)
        detalle.textColor = .secondaryLabel
        let pila = UIStackView(arrangedSubviews: [titulo, monto, detalle])
        pila.axis = .vertical
        pila.spacing = 2
        pila.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pila)
        NSLayoutConstraint.activate([
            pila.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            pila.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            pila.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            pila.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])
        isAccessibilityElement = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    func mostrar(monto valor: Double, cantidad: Int) {
        monto.text = Formato.soles(valor)
        detalle.text = cantidad == 1 ? "1 venta" : "\(cantidad) ventas"
        accessibilityLabel = titulo.text
        accessibilityValue = "\(monto.text ?? "") · \(detalle.text ?? "")"
    }
}
