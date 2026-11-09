//
//  SeleccionViewController.swift
//  Laboratorio12-GrupoA
//
//  Lista para elegir el cliente o el producto de la venta (A5 ②, ③).
//

import UIKit

final class SeleccionViewController: UITableViewController {

    private let opciones: [(titulo: String, detalle: String)]
    private let alElegir: (Int) -> Void

    init(titulo: String, opciones: [(String, String)], alElegir: @escaping (Int) -> Void) {
        self.opciones = opciones.map { (titulo: $0.0, detalle: $0.1) }
        self.alElegir = alElegir
        super.init(style: .insetGrouped)
        title = titulo
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        opciones.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let celda = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        celda.textLabel?.text = opciones[indexPath.row].titulo
        celda.detailTextLabel?.text = opciones[indexPath.row].detalle
        celda.detailTextLabel?.textColor = .secondaryLabel
        return celda
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        alElegir(indexPath.row)
        navigationController?.popViewController(animated: true)
    }
}
