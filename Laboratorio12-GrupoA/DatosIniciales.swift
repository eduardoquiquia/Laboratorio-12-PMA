//
//  DatosIniciales.swift
//  Laboratorio12-GrupoA
//
//  Carga de datos de prueba (seed) la primera vez que se abre la app.
//  Los datos siguen las maquetas A3, A4 y A7 del laboratorio.
//  Usuarios de prueba (clave "123456"):
//    - cruiz  · Carlos Ruiz · Vendedor
//    - adiaz  · Ana Díaz    · Vendedor
//  El supervisor "lparedes" NO se carga: se registra en el caso de prueba 1.
//

import Foundation
import CoreData

enum DatosIniciales {

    /// Carga el seed solo si la base de datos está vacía.
    static func cargarSiEsNecesario(en contexto: NSManagedObjectContext) {
        let hayUsuarios = (try? contexto.count(for: Usuario.fetchRequest())) ?? 0
        let hayProductos = (try? contexto.count(for: Producto.fetchRequest())) ?? 0
        let hayClientes = (try? contexto.count(for: Cliente.fetchRequest())) ?? 0
        guard hayUsuarios == 0, hayProductos == 0, hayClientes == 0 else { return }

        // Usuarios
        let carlos = crearUsuario("Carlos Ruiz", usuario: "cruiz", clave: "123456", rol: "Vendedor", en: contexto)
        let ana = crearUsuario("Ana Díaz", usuario: "adiaz", clave: "123456", rol: "Vendedor", en: contexto)

        // Productos (A3)
        let laptop = crearProducto("Laptop Pro 14", categoria: "Laptops", precio: 200.00, stock: 40, en: contexto)
        let monitor = crearProducto("Monitor 24\"", categoria: "Monitores", precio: 450.00, stock: 9, en: contexto)
        let mouse = crearProducto("Mouse inalámbrico", categoria: "Accesorios", precio: 35.00, stock: 120, en: contexto)
        let teclado = crearProducto("Teclado mecánico", categoria: "Accesorios", precio: 129.90, stock: 4, en: contexto)

        // Clientes (A4)
        let andina = crearCliente("Comercial Andina SAC", documento: "RUC 20000000001", en: contexto)
        let maria = crearCliente("María Quispe", documento: "DNI 00000001", en: contexto)
        let luis = crearCliente("Luis Rojas", documento: "DNI 00000002", en: contexto)
        let tienda = crearCliente("Tienda Sol EIRL", documento: "RUC 20000000044", en: contexto)

        // Ventas históricas (en orden cronológico; el descuento VIP se aplica
        // según lo comprado por el cliente antes de cada venta).
        crearVenta(diasAtras: 10, cantidad: 6, producto: monitor, cliente: andina, vendedor: carlos, en: contexto)
        crearVenta(diasAtras: 8, cantidad: 8, producto: laptop, cliente: andina, vendedor: ana, en: contexto)
        crearVenta(diasAtras: 5, cantidad: 3, producto: monitor, cliente: maria, vendedor: carlos, en: contexto)
        crearVenta(diasAtras: 4, cantidad: 1, producto: monitor, cliente: maria, vendedor: carlos,
                   anulada: true, motivo: "Producto defectuoso", en: contexto)
        crearVenta(diasAtras: 3, cantidad: 5, producto: mouse, cliente: luis, vendedor: ana, en: contexto)
        crearVenta(diasAtras: 2, cantidad: 1, producto: teclado, cliente: luis, vendedor: carlos, en: contexto)
        crearVenta(diasAtras: 1, cantidad: 2, producto: mouse, cliente: tienda, vendedor: ana, en: contexto)

        do {
            try contexto.save()
        } catch {
            contexto.rollback()
            print("No se pudo cargar el seed: \(error)")
        }
    }

    // MARK: - Ayudantes

    @discardableResult
    private static func crearUsuario(_ nombre: String, usuario: String, clave: String, rol: String,
                                     en contexto: NSManagedObjectContext) -> Usuario {
        let u = Usuario(context: contexto)
        u.nombre = nombre
        u.usuario = usuario
        u.clave = clave
        u.rol = rol
        return u
    }

    private static func crearProducto(_ nombre: String, categoria: String, precio: Double, stock: Int64,
                                      en contexto: NSManagedObjectContext) -> Producto {
        let p = Producto(context: contexto)
        p.nombre = nombre
        p.categoria = categoria
        p.precio = precio
        p.stock = stock
        return p
    }

    private static func crearCliente(_ nombre: String, documento: String,
                                     en contexto: NSManagedObjectContext) -> Cliente {
        let c = Cliente(context: contexto)
        c.nombre = nombre
        c.documento = documento
        return c
    }

    /// Venta histórica: no descuenta stock (el stock cargado ya es el actual).
    private static func crearVenta(diasAtras: Int, cantidad: Int64, producto: Producto, cliente: Cliente,
                                   vendedor: Usuario, anulada: Bool = false, motivo: String? = nil,
                                   en contexto: NSManagedObjectContext) {
        let compradoAntes = (cliente.ventas as? Set<Venta> ?? [])
            .filter { !$0.anulada }
            .reduce(0) { $0 + $1.total }
        let esVIP = compradoAntes >= 5000

        let subtotal = redondear(Double(cantidad) * producto.precio)
        let descuento = esVIP ? redondear(subtotal * 0.10) : 0
        let igv = redondear((subtotal - descuento) * 0.18)
        let total = redondear(subtotal - descuento + igv)

        let v = Venta(context: contexto)
        v.fecha = Calendar.current.date(byAdding: .day, value: -diasAtras, to: Date())
        v.cantidad = cantidad
        v.precioUnitario = producto.precio
        v.descuento = descuento
        v.igv = igv
        v.total = total
        v.anulada = anulada
        v.motivoAnulacion = motivo
        v.producto = producto
        v.cliente = cliente
        v.vendedor = vendedor
    }

    private static func redondear(_ valor: Double) -> Double {
        (valor * 100).rounded() / 100
    }
}
