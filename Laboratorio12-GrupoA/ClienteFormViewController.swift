//
//  ClienteFormViewController.swift
//  Laboratorio12-GrupoA
//
//  Crear o editar un cliente (ambos roles): nombre y documento.
//

import UIKit
import CoreData

final class ClienteFormViewController: UIViewController {

    private let cliente: Cliente?
    private let campoNombre = CampoTarjeta(titulo: "Nombre")
    private let campoDocumento = CampoTarjeta(titulo: "Documento")

    init(cliente: Cliente?) {
        self.cliente = cliente
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = cliente == nil ? "Nuevo cliente" : "Editar cliente"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Guardar", style: .prominent, target: self, action: #selector(guardar))

        campoNombre.campo.autocapitalizationType = .words
        campoDocumento.campo.autocapitalizationType = .allCharacters

        if let cliente {
            campoNombre.campo.text = cliente.nombre
            campoDocumento.campo.text = cliente.documento
        }

        let formulario = UIStackView(arrangedSubviews: [campoNombre, campoDocumento])
        formulario.axis = .vertical
        formulario.spacing = 14
        formulario.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(formulario)
        NSLayoutConstraint.activate([
            formulario.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            formulario.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            formulario.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func guardar() {
        view.endEditing(true)
        let nombre = campoNombre.texto
        let documento = campoDocumento.texto

        guard !nombre.isEmpty else {
            mostrarAlerta("Datos incompletos", "Ingresa el nombre del cliente.")
            return
        }
        guard !documento.isEmpty else {
            mostrarAlerta("Datos incompletos", "Ingresa el documento del cliente.")
            return
        }

        let contexto = AppDelegate.contexto
        let destino = cliente ?? Cliente(context: contexto)
        destino.nombre = nombre
        destino.documento = documento

        do {
            try contexto.save()
        } catch {
            contexto.rollback()
            mostrarAlerta("Error", "No se pudo guardar el cliente.")
            return
        }
        navigationController?.popViewController(animated: true)
    }
}
