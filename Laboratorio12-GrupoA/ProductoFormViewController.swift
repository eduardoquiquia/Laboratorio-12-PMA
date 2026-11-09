//
//  ProductoFormViewController.swift
//  Laboratorio12-GrupoA
//
//  Crear o editar un producto (solo supervisor): nombre, categoría,
//  precio (Double) y stock (Int).
//

import UIKit
import CoreData

final class ProductoFormViewController: UIViewController {

    private let producto: Producto?
    private let campoNombre = CampoTarjeta(titulo: "Nombre")
    private let campoCategoria = CampoTarjeta(titulo: "Categoría")
    private let campoPrecio = CampoTarjeta(titulo: "Precio (S/)")
    private let campoStock = CampoTarjeta(titulo: "Stock")

    init(producto: Producto?) {
        self.producto = producto
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no se usa") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = producto == nil ? "Nuevo producto" : "Editar producto"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Guardar", style: .prominent, target: self, action: #selector(guardar))

        campoNombre.campo.autocapitalizationType = .sentences
        campoCategoria.campo.autocapitalizationType = .words
        campoPrecio.campo.keyboardType = .decimalPad
        campoStock.campo.keyboardType = .numberPad

        if let producto {
            campoNombre.campo.text = producto.nombre
            campoCategoria.campo.text = producto.categoria
            campoPrecio.campo.text = String(format: "%.2f", producto.precio)
            campoStock.campo.text = "\(producto.stock)"
        }

        let formulario = UIStackView(arrangedSubviews: [campoNombre, campoCategoria, campoPrecio, campoStock])
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
        guard Sesion.compartida.esSupervisor else { return }

        let nombre = campoNombre.texto
        let categoria = campoCategoria.texto
        let precioTexto = campoPrecio.texto.replacingOccurrences(of: ",", with: ".")

        guard !nombre.isEmpty else {
            mostrarAlerta("Datos incompletos", "Ingresa el nombre del producto.")
            return
        }
        guard !categoria.isEmpty else {
            mostrarAlerta("Datos incompletos", "Ingresa la categoría del producto.")
            return
        }
        guard let precio = Double(precioTexto), precio > 0 else {
            mostrarAlerta("Precio inválido", "Ingresa un precio mayor que 0.")
            return
        }
        guard let stock = Int64(campoStock.texto), stock >= 0 else {
            mostrarAlerta("Stock inválido", "Ingresa un stock entero de 0 o más.")
            return
        }

        let contexto = AppDelegate.contexto
        let destino = producto ?? Producto(context: contexto)
        destino.nombre = nombre
        destino.categoria = categoria
        destino.precio = precio
        destino.stock = stock

        do {
            try contexto.save()
        } catch {
            contexto.rollback()
            mostrarAlerta("Error", "No se pudo guardar el producto.")
            return
        }
        navigationController?.popViewController(animated: true)
    }
}
