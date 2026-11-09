//
//  CuentaViewController.swift
//  Laboratorio12-GrupoA
//
//  Pestaña Cuenta: nombre, usuario, rol y botón Cerrar sesión.
//

import UIKit

final class CuentaViewController: UITableViewController {

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cuenta"
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 2 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 3 : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if indexPath.section == 0 {
            let usuario = Sesion.compartida.usuarioActual
            let filas = [
                ("Nombre", usuario?.nombre),
                ("Usuario", usuario?.usuario),
                ("Rol", usuario?.rol)
            ]
            celda.textLabel?.text = filas[indexPath.row].0
            celda.detailTextLabel?.text = filas[indexPath.row].1
            celda.selectionStyle = .none
        } else {
            celda.textLabel?.text = "Cerrar sesión"
            celda.textLabel?.textColor = .systemRed
            celda.textLabel?.textAlignment = .center
        }
        return celda
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1 else { return }
        Sesion.compartida.usuarioActual = nil
        sceneDelegate?.mostrarLogin()
    }
}
