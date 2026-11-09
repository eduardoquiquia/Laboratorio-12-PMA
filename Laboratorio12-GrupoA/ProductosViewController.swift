//
//  ProductosViewController.swift
//  Laboratorio12-GrupoA
//
//  A3 · Productos: título y botón + (solo supervisor), búsqueda, chips de
//  categoría (predicate), fila con stock en color y deslizar para borrar
//  (solo supervisor; bloqueado si tiene ventas).
//  Vendedor: solo consultar y buscar. Supervisor: crear, editar y borrar.
//

import UIKit
import CoreData

final class ProductosViewController: UITableViewController {

    private var productos: [Producto] = []
    private var categorias: [String] = []
    private var categoriaSeleccionada: String?
    private let buscador = UISearchController(searchResultsController: nil)
    private let chips = BarraChips()

    private var esSupervisor: Bool { Sesion.compartida.esSupervisor }

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Productos"

        if esSupervisor {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .add, target: self, action: #selector(nuevoProducto))
            navigationItem.rightBarButtonItem?.accessibilityLabel = "Nuevo producto"
        }

        buscador.searchResultsUpdater = self
        buscador.obscuresBackgroundDuringPresentation = false
        buscador.searchBar.placeholder = "Buscar producto"
        navigationItem.searchController = buscador
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        chips.alSeleccionar = { [weak self] indice in
            guard let self else { return }
            self.categoriaSeleccionada = indice == 0 ? nil : self.categorias[indice - 1]
            self.cargarProductos()
        }
        let cabecera = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 48))
        chips.frame = cabecera.bounds.insetBy(dx: 0, dy: 6)
        chips.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cabecera.addSubview(chips)
        tableView.tableHeaderView = cabecera

        tableView.register(ProductoCelda.self, forCellReuseIdentifier: ProductoCelda.id)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cargarCategorias()
        cargarProductos()
    }

    // MARK: - Fetch con predicates

    /// Categorías distintas existentes, para los chips.
    private func cargarCategorias() {
        let pedido = NSFetchRequest<NSDictionary>(entityName: "Producto")
        pedido.resultType = .dictionaryResultType
        pedido.propertiesToFetch = ["categoria"]
        pedido.returnsDistinctResults = true
        pedido.sortDescriptors = [NSSortDescriptor(key: "categoria", ascending: true)]
        let filas = (try? AppDelegate.contexto.fetch(pedido)) ?? []
        categorias = filas.compactMap { $0["categoria"] as? String }

        if let actual = categoriaSeleccionada, !categorias.contains(actual) {
            categoriaSeleccionada = nil
        }
        let indice = categoriaSeleccionada.flatMap { categorias.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
        chips.configurar(["Todos"] + categorias, seleccionado: indice)
    }

    private func cargarProductos() {
        let pedido = Producto.fetchRequest()
        var condiciones: [NSPredicate] = []
        if let categoria = categoriaSeleccionada {
            condiciones.append(NSPredicate(format: "categoria == %@", categoria))
        }
        let texto = (buscador.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !texto.isEmpty {
            condiciones.append(NSPredicate(format: "nombre CONTAINS[cd] %@", texto))
        }
        pedido.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: condiciones)
        pedido.sortDescriptors = [NSSortDescriptor(key: "nombre", ascending: true,
                                                   selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        productos = (try? AppDelegate.contexto.fetch(pedido)) ?? []
        tableView.reloadData()
    }

    // MARK: - Tabla

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        productos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(withIdentifier: ProductoCelda.id, for: indexPath) as! ProductoCelda
        celda.configurar(productos[indexPath.row])
        celda.selectionStyle = esSupervisor ? .default : .none
        celda.accessoryType = .none
        return celda
    }

    /// Editar: solo supervisor.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard esSupervisor else { return }
        navigationController?.pushViewController(ProductoFormViewController(producto: productos[indexPath.row]), animated: true)
    }

    // MARK: - Borrar (solo supervisor)

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        esSupervisor
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        esSupervisor ? .delete : .none
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard esSupervisor else { return nil }
        let borrar = UIContextualAction(style: .destructive, title: "Borrar") { [weak self] _, _, terminar in
            terminar(self?.borrar(en: indexPath) ?? false)
        }
        return UISwipeActionsConfiguration(actions: [borrar])
    }

    /// Intenta borrar; la regla Deny de Producto.ventas impide guardar si el producto tiene ventas.
    private func borrar(en indexPath: IndexPath) -> Bool {
        let producto = productos[indexPath.row]
        let nombre = producto.nombre ?? ""
        let contexto = AppDelegate.contexto
        contexto.delete(producto)
        do {
            try contexto.save()
        } catch {
            contexto.rollback()
            if (error as NSError).code == NSValidationRelationshipDeniedDeleteError {
                mostrarAlerta("No se puede borrar",
                              "\"\(nombre)\" tiene ventas registradas. Un producto con ventas no se puede borrar.")
            } else {
                mostrarAlerta("Error", "No se pudo borrar el producto.")
            }
            return false
        }
        productos.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        cargarCategorias()
        return true
    }

    // MARK: - Crear (solo supervisor)

    @objc private func nuevoProducto() {
        guard esSupervisor else { return }
        navigationController?.pushViewController(ProductoFormViewController(producto: nil), animated: true)
    }
}

extension ProductosViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        cargarProductos()
    }
}

// MARK: - Celda

final class ProductoCelda: UITableViewCell {
    static let id = "ProductoCelda"

    private let avatar = AvatarIniciales()
    private let nombre = UILabel()
    private let categoria = UILabel()
    private let precio = UILabel()
    private let stock = Pastilla()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        nombre.font = .systemFont(ofSize: 16, weight: .semibold)
        categoria.font = .systemFont(ofSize: 13)
        categoria.textColor = .secondaryLabel
        precio.font = .systemFont(ofSize: 15, weight: .semibold)
        precio.setContentHuggingPriority(.required, for: .horizontal)
        precio.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textos = UIStackView(arrangedSubviews: [nombre, categoria])
        textos.axis = .vertical
        textos.spacing = 2
        let fila = UIStackView(arrangedSubviews: [avatar, textos, precio, stock])
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

    func configurar(_ producto: Producto) {
        let texto = producto.nombre ?? ""
        avatar.configurar(texto)
        nombre.text = texto
        categoria.text = producto.categoria
        precio.text = Formato.soles(producto.precio)
        stock.configurar("\(producto.stock) u.", color: Estilo.colorStock(producto.stock))
    }
}
