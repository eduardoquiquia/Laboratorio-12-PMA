//
//  ClientesViewController.swift
//  Laboratorio12-GrupoA
//
//  A4 · Clientes: botón +, fila con iniciales, nombre, documento y total
//  comprado; categoría y total calculados con las ventas no anuladas.
//  Vendedor: crear, editar y consultar. Supervisor: además borrar.
//

import UIKit
import CoreData

final class ClientesViewController: UITableViewController {

    private var clientes: [Cliente] = []
    private let buscador = UISearchController(searchResultsController: nil)

    private var esSupervisor: Bool { Sesion.compartida.esSupervisor }

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Clientes"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(nuevoCliente))
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Nuevo cliente"

        buscador.searchResultsUpdater = self
        buscador.obscuresBackgroundDuringPresentation = false
        buscador.searchBar.placeholder = "Buscar por nombre o documento"
        navigationItem.searchController = buscador
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        tableView.register(ClienteCelda.self, forCellReuseIdentifier: ClienteCelda.id)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cargarClientes()
    }

    private func cargarClientes() {
        let pedido = Cliente.fetchRequest()
        let texto = (buscador.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !texto.isEmpty {
            pedido.predicate = NSPredicate(format: "nombre CONTAINS[cd] %@ OR documento CONTAINS[cd] %@", texto, texto)
        }
        pedido.sortDescriptors = [NSSortDescriptor(key: "nombre", ascending: true,
                                                   selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        clientes = (try? AppDelegate.contexto.fetch(pedido)) ?? []
        tableView.reloadData()
    }

    // MARK: - Tabla

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        clientes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = tableView.dequeueReusableCell(withIdentifier: ClienteCelda.id, for: indexPath) as! ClienteCelda
        celda.configurar(clientes[indexPath.row])
        return celda
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "Categoría y \"comprado\" se calculan con las ventas no anuladas; no se guardan."
    }

    /// Editar: ambos roles.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(ClienteFormViewController(cliente: clientes[indexPath.row]), animated: true)
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

    /// Intenta borrar; la regla Deny de Cliente.ventas impide guardar si el cliente tiene ventas.
    private func borrar(en indexPath: IndexPath) -> Bool {
        let cliente = clientes[indexPath.row]
        let nombre = cliente.nombre ?? ""
        let contexto = AppDelegate.contexto
        contexto.delete(cliente)
        do {
            try contexto.save()
        } catch {
            contexto.rollback()
            if (error as NSError).code == NSValidationRelationshipDeniedDeleteError {
                mostrarAlerta("No se puede borrar",
                              "\"\(nombre)\" tiene ventas registradas. Un cliente con ventas no se puede borrar.")
            } else {
                mostrarAlerta("Error", "No se pudo borrar el cliente.")
            }
            return false
        }
        clientes.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        return true
    }

    // MARK: - Crear (ambos roles)

    @objc private func nuevoCliente() {
        navigationController?.pushViewController(ClienteFormViewController(cliente: nil), animated: true)
    }
}

extension ClientesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        cargarClientes()
    }
}

extension CategoriaCliente {
    var color: UIColor {
        switch self {
        case .vip: return .systemPurple
        case .frecuente: return .systemBlue
        case .regular: return .systemGray
        }
    }
}

// MARK: - Celda

final class ClienteCelda: UITableViewCell {
    static let id = "ClienteCelda"

    private let avatar = AvatarIniciales()
    private let nombre = UILabel()
    private let documento = UILabel()
    private let total = UILabel()
    private let comprado = UILabel()
    private let categoria = Pastilla()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        nombre.font = .systemFont(ofSize: 16, weight: .semibold)
        documento.font = .systemFont(ofSize: 13)
        documento.textColor = .secondaryLabel
        total.font = .systemFont(ofSize: 15, weight: .semibold)
        total.textAlignment = .right
        comprado.text = "comprado"
        comprado.font = .systemFont(ofSize: 12)
        comprado.textColor = .secondaryLabel
        comprado.textAlignment = .right

        let textos = UIStackView(arrangedSubviews: [nombre, documento])
        textos.axis = .vertical
        textos.spacing = 2
        let montos = UIStackView(arrangedSubviews: [total, comprado])
        montos.axis = .vertical
        montos.alignment = .trailing
        montos.setContentHuggingPriority(.required, for: .horizontal)
        montos.setContentCompressionResistancePriority(.required, for: .horizontal)

        let fila = UIStackView(arrangedSubviews: [avatar, textos, montos, categoria])
        fila.alignment = .center
        fila.spacing = 10
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

    func configurar(_ cliente: Cliente) {
        let texto = cliente.nombre ?? ""
        let categoriaCliente = cliente.categoriaCalculada
        avatar.configurar(texto, color: categoriaCliente == .regular ? .systemGray : nil)
        nombre.text = texto
        documento.text = cliente.documento
        total.text = Formato.soles(cliente.totalComprado)
        categoria.configurar(categoriaCliente.rawValue, color: categoriaCliente.color)
    }
}
