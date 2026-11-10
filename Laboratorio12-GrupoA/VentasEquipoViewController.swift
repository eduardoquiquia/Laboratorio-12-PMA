//
//  VentasEquipoViewController.swift
//  Laboratorio12-GrupoA
//
//  A7 · Ventas del equipo (solo supervisor): ① chips por vendedor,
//  ② venta con el nombre del vendedor (relación venta ▶ vendedor),
//  ③ deslizar para Anular (solo supervisor), ④ nota de la relación.
//  A8 · Anular venta: alerta con el resumen y aviso de devolución de stock,
//  motivo obligatorio, botón Anular deshabilitado mientras el motivo esté vacío.
//

import UIKit
import CoreData

final class VentasEquipoViewController: UITableViewController {

    private var ventas: [Venta] = []
    private var vendedores: [Usuario] = []
    private var vendedorSeleccionado: Usuario?
    private let buscador = UISearchController(searchResultsController: nil)
    private let segmentado = UISegmentedControl(items: PeriodoVenta.allCases.map(\.titulo))
    private let chips = BarraChips()

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Ventas del equipo"   // la pestaña conserva "Ventas"

        let iniciales = UILabel()
        iniciales.text = Formato.iniciales(Sesion.compartida.usuarioActual?.nombre ?? "")
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

        chips.alSeleccionar = { [weak self] indice in
            guard let self else { return }
            self.vendedorSeleccionado = indice == 0 ? nil : self.vendedores[indice - 1]
            self.cargarVentas()
        }

        let contenedorSegmentado = UIView()
        segmentado.translatesAutoresizingMaskIntoConstraints = false
        contenedorSegmentado.addSubview(segmentado)
        NSLayoutConstraint.activate([
            segmentado.topAnchor.constraint(equalTo: contenedorSegmentado.topAnchor),
            segmentado.bottomAnchor.constraint(equalTo: contenedorSegmentado.bottomAnchor),
            segmentado.leadingAnchor.constraint(equalTo: contenedorSegmentado.leadingAnchor, constant: 20),
            segmentado.trailingAnchor.constraint(equalTo: contenedorSegmentado.trailingAnchor, constant: -20)
        ])
        chips.heightAnchor.constraint(equalToConstant: 36).isActive = true
        let cabecera = UIStackView(arrangedSubviews: [contenedorSegmentado, chips])
        cabecera.axis = .vertical
        cabecera.spacing = 12
        cabecera.isLayoutMarginsRelativeArrangement = true
        cabecera.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0)
        cabecera.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 96)
        tableView.tableHeaderView = cabecera

        tableView.register(VentaCelda.self, forCellReuseIdentifier: VentaCelda.id)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cargarVendedores()
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

    /// ① Chips: usuarios con rol Vendedor.
    private func cargarVendedores() {
        let pedido = Usuario.fetchRequest()
        pedido.predicate = NSPredicate(format: "rol == %@", Rol.vendedor)
        pedido.sortDescriptors = [NSSortDescriptor(key: "nombre", ascending: true,
                                                   selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        vendedores = (try? AppDelegate.contexto.fetch(pedido)) ?? []
        if let actual = vendedorSeleccionado, !vendedores.contains(actual) {
            vendedorSeleccionado = nil
        }
        let indice = vendedorSeleccionado.flatMap { vendedores.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
        chips.configurar(["Todos"] + vendedores.map { $0.nombre ?? "" }, seleccionado: indice)
    }

    /// Todas las ventas, o solo las del vendedor elegido ("vendedor == %@"), por periodo y cliente.
    @objc private func cargarVentas() {
        let periodo = PeriodoVenta(rawValue: segmentado.selectedSegmentIndex) ?? .todas
        let pedido = FiltroVentas.pedido(vendedor: vendedorSeleccionado, periodo: periodo,
                                         cliente: buscador.searchBar.text ?? "")
        ventas = (try? AppDelegate.contexto.fetch(pedido)) ?? []
        tableView.reloadData()
    }

    // MARK: - Tabla

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        ventas.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(withIdentifier: VentaCelda.id, for: indexPath) as! VentaCelda
        celda.configurar(ventas[indexPath.row], modo: .conVendedor)
        return celda
    }

    /// ④ Nota de la relación.
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "El nombre del vendedor se lee de la relación venta ▶ vendedor."
    }

    // MARK: - ③ Deslizar para Anular (solo supervisor, ventas no anuladas)

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        Sesion.compartida.esSupervisor && !ventas[indexPath.row].anulada
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let venta = ventas[indexPath.row]
        guard Sesion.compartida.esSupervisor, !venta.anulada else { return nil }
        let anular = UIContextualAction(style: .destructive, title: "Anular") { [weak self] _, _, terminar in
            self?.confirmarAnulacion(de: venta)
            terminar(true)
        }
        let configuracion = UISwipeActionsConfiguration(actions: [anular])
        configuracion.performsFirstActionWithFullSwipe = false
        return configuracion
    }

    // MARK: - A8 · Anular venta

    private func confirmarAnulacion(de venta: Venta) {
        let resumen = "\(venta.cliente?.nombre ?? "") · \(venta.producto?.nombre ?? "") × \(venta.cantidad) · \(Formato.soles(venta.total))"
        let alerta = UIAlertController(
            title: "Anular venta",
            message: "\(resumen)\nEl stock se devolverá (+\(venta.cantidad)).",
            preferredStyle: .alert)

        let accionAnular = UIAlertAction(title: "Anular", style: .destructive) { [weak self, weak alerta] _ in
            let motivo = alerta?.textFields?.first?.text ?? ""
            self?.anular(venta, motivo: motivo)
        }
        accionAnular.isEnabled = false   // deshabilitado mientras el motivo esté vacío

        alerta.addTextField { campo in
            campo.placeholder = "Motivo (obligatorio)"
            campo.autocapitalizationType = .sentences
            campo.addAction(UIAction { [weak campo] _ in
                let texto = (campo?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                accionAnular.isEnabled = !texto.isEmpty
            }, for: .editingChanged)
        }
        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alerta.addAction(accionAnular)
        present(alerta, animated: true)
    }

    private func anular(_ venta: Venta, motivo: String) {
        do {
            try OperacionesVenta.anular(venta, motivo: motivo, en: AppDelegate.contexto)
        } catch ErrorVenta.motivoVacio {
            mostrarAlerta("Motivo obligatorio", "Escribe el motivo de la anulación.")
        } catch {
            mostrarAlerta("Error", "No se pudo anular la venta.")
        }
        cargarVentas()
    }
}

extension VentasEquipoViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        cargarVentas()
    }
}
