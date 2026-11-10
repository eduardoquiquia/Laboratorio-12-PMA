//
//  ReglasNegocio.swift
//  Laboratorio12-GrupoA
//
//  Reglas del caso Ventas (Grupo A).
//

import Foundation
import CoreData

/// Categoría del cliente (calculada, no guardada) según lo comprado en ventas no anuladas:
/// Regular < S/ 1,000 · Frecuente desde S/ 1,000 · VIP desde S/ 5,000.
enum CategoriaCliente: String {
    case regular = "Regular"
    case frecuente = "Frecuente"
    case vip = "VIP"

    static func para(totalComprado: Double) -> CategoriaCliente {
        if totalComprado >= 5000 { return .vip }
        if totalComprado >= 1000 { return .frecuente }
        return .regular
    }
}

extension Cliente {
    /// Suma del total de sus ventas no anuladas.
    var totalComprado: Double {
        (ventas as? Set<Venta> ?? [])
            .filter { !$0.anulada }
            .reduce(0) { $0 + $1.total }
    }

    var categoriaCalculada: CategoriaCliente {
        .para(totalComprado: totalComprado)
    }
}

// MARK: - Cálculo de la venta

/// Subtotal = cantidad × precioUnitario
/// Descuento = 10 % del subtotal si el cliente es VIP; 0 % en otro caso
/// IGV = 18 % × (subtotal − descuento)
/// Total = subtotal − descuento + IGV
struct CalculoVenta {
    let subtotal: Double
    let descuento: Double
    let igv: Double
    let total: Double

    static let tasaDescuentoVIP = 0.10
    static let tasaIGV = 0.18

    init(cantidad: Int64, precioUnitario: Double, categoria: CategoriaCliente) {
        subtotal = Self.redondear(Double(cantidad) * precioUnitario)
        descuento = categoria == .vip ? Self.redondear(subtotal * Self.tasaDescuentoVIP) : 0
        igv = Self.redondear((subtotal - descuento) * Self.tasaIGV)
        total = Self.redondear(subtotal - descuento + igv)
    }

    private static func redondear(_ valor: Double) -> Double {
        (valor * 100).rounded() / 100
    }
}

// MARK: - Registrar venta

enum ErrorVenta: Error {
    case stockInsuficiente(disponible: Int64)
    case noGuardada
    case sinPermiso
    case motivoVacio
    case yaAnulada
}

enum OperacionesVenta {
    /// Registra la venta: valida el stock, calcula descuento/IGV/total, guarda la venta
    /// con sus relaciones (vendedor, producto, cliente) y descuenta el stock.
    /// Si la cantidad supera el stock no registra nada.
    @discardableResult
    static func registrar(cantidad: Int64, producto: Producto, cliente: Cliente, vendedor: Usuario,
                          en contexto: NSManagedObjectContext) throws -> Venta {
        guard cantidad <= producto.stock else {
            throw ErrorVenta.stockInsuficiente(disponible: producto.stock)
        }
        let calculo = CalculoVenta(cantidad: cantidad, precioUnitario: producto.precio,
                                   categoria: cliente.categoriaCalculada)
        let venta = Venta(context: contexto)
        venta.fecha = Date()
        venta.cantidad = cantidad
        venta.precioUnitario = producto.precio
        venta.descuento = calculo.descuento
        venta.igv = calculo.igv
        venta.total = calculo.total
        venta.anulada = false
        venta.vendedor = vendedor
        venta.producto = producto
        venta.cliente = cliente
        producto.stock -= cantidad

        do {
            try contexto.save()
        } catch {
            contexto.rollback()
            throw ErrorVenta.noGuardada
        }
        return venta
    }

    /// Anula la venta (solo supervisor): exige motivo, marca la venta como anulada,
    /// guarda el motivo y devuelve las unidades al stock del producto.
    /// Una venta anulada deja de contar en reportes y en la categoría del cliente.
    static func anular(_ venta: Venta, motivo: String, en contexto: NSManagedObjectContext) throws {
        let motivoLimpio = motivo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Sesion.compartida.esSupervisor else { throw ErrorVenta.sinPermiso }
        guard !motivoLimpio.isEmpty else { throw ErrorVenta.motivoVacio }
        guard !venta.anulada else { throw ErrorVenta.yaAnulada }

        venta.anulada = true
        venta.motivoAnulacion = motivoLimpio
        venta.producto?.stock += venta.cantidad

        do {
            try contexto.save()
        } catch {
            contexto.rollback()
            throw ErrorVenta.noGuardada
        }
    }
}

// MARK: - Filtros de ventas con NSPredicate

/// Segmentado Todas / Hoy / Mes (A6, A7).
enum PeriodoVenta: Int, CaseIterable {
    case todas, hoy, mes

    var titulo: String {
        switch self {
        case .todas: return "Todas"
        case .hoy: return "Hoy"
        case .mes: return "Mes"
        }
    }

    /// Rango [inicio, fin) del periodo; nil para "Todas".
    func rango(referencia: Date = Date(), calendario: Calendar = .current) -> (inicio: Date, fin: Date)? {
        switch self {
        case .todas:
            return nil
        case .hoy:
            let inicio = calendario.startOfDay(for: referencia)
            return (inicio, calendario.date(byAdding: .day, value: 1, to: inicio)!)
        case .mes:
            let inicio = calendario.date(from: calendario.dateComponents([.year, .month], from: referencia))!
            return (inicio, calendario.date(byAdding: .month, value: 1, to: inicio)!)
        }
    }

    /// Predicate por fechas: fecha >= inicio AND fecha < fin.
    func predicado(referencia: Date = Date()) -> NSPredicate? {
        guard let rango = rango(referencia: referencia) else { return nil }
        return NSPredicate(format: "fecha >= %@ AND fecha < %@", rango.inicio as NSDate, rango.fin as NSDate)
    }
}

enum FiltroVentas {
    /// Combina los filtros: vendedor (relación), periodo (fechas), cliente (búsqueda) y solo no anuladas.
    static func pedido(vendedor: Usuario?, periodo: PeriodoVenta, cliente texto: String = "",
                       soloNoAnuladas: Bool = false, referencia: Date = Date()) -> NSFetchRequest<Venta> {
        let pedido = Venta.fetchRequest()
        var condiciones: [NSPredicate] = []
        if let vendedor {
            condiciones.append(NSPredicate(format: "vendedor == %@", vendedor))
        }
        if let porFecha = periodo.predicado(referencia: referencia) {
            condiciones.append(porFecha)
        }
        let busqueda = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        if !busqueda.isEmpty {
            condiciones.append(NSPredicate(format: "cliente.nombre CONTAINS[cd] %@", busqueda))
        }
        if soloNoAnuladas {
            condiciones.append(NSPredicate(format: "anulada == NO"))
        }
        pedido.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: condiciones)
        pedido.sortDescriptors = [NSSortDescriptor(key: "fecha", ascending: false)]
        return pedido
    }
}
