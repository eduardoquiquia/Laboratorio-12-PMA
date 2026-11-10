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

// MARK: - Resumen del supervisor (A9) con Fetch Requests

enum ConsultasResumen {

    /// Suma del total de las ventas no anuladas del día que contiene `dia`.
    static func vendidoDelDia(_ dia: Date, en contexto: NSManagedObjectContext) -> Double {
        let pedido = FiltroVentas.pedido(vendedor: nil, periodo: .hoy, soloNoAnuladas: true, referencia: dia)
        return ((try? contexto.fetch(pedido)) ?? []).reduce(0) { $0 + $1.total }
    }

    /// IGV de las ventas no anuladas del mes actual.
    static func igvDelMes(en contexto: NSManagedObjectContext, referencia: Date = Date()) -> Double {
        let pedido = FiltroVentas.pedido(vendedor: nil, periodo: .mes, soloNoAnuladas: true, referencia: referencia)
        return ((try? contexto.fetch(pedido)) ?? []).reduce(0) { $0 + $1.igv }
    }

    /// Vendido (no anulado) en cada uno de los últimos 7 días, del más antiguo a hoy.
    static func ultimos7Dias(en contexto: NSManagedObjectContext, referencia: Date = Date(),
                             calendario: Calendar = .current) -> [(dia: Date, monto: Double)] {
        let hoy = calendario.startOfDay(for: referencia)
        let inicio = calendario.date(byAdding: .day, value: -6, to: hoy)!
        let fin = calendario.date(byAdding: .day, value: 1, to: hoy)!

        let pedido = Venta.fetchRequest()
        pedido.predicate = NSPredicate(format: "fecha >= %@ AND fecha < %@ AND anulada == NO",
                                       inicio as NSDate, fin as NSDate)
        let ventas = (try? contexto.fetch(pedido)) ?? []

        return (0..<7).map { desplazamiento in
            let dia = calendario.date(byAdding: .day, value: desplazamiento, to: inicio)!
            let monto = ventas
                .filter { $0.fecha.map { calendario.isDate($0, inSameDayAs: dia) } ?? false }
                .reduce(0) { $0 + $1.total }
            return (dia, monto)
        }
    }

    /// Ranking de vendedores del mes: suma de total (no anuladas) agrupada por vendedor, de mayor a menor.
    static func rankingDelMes(en contexto: NSManagedObjectContext,
                              referencia: Date = Date()) -> [(nombre: String, monto: Double)] {
        let pedido = NSFetchRequest<NSDictionary>(entityName: "Venta")
        var condiciones = [NSPredicate(format: "anulada == NO")]
        if let porMes = PeriodoVenta.mes.predicado(referencia: referencia) {
            condiciones.append(porMes)
        }
        pedido.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: condiciones)

        let suma = NSExpressionDescription()
        suma.name = "monto"
        suma.expression = NSExpression(forFunction: "sum:", arguments: [NSExpression(forKeyPath: "total")])
        suma.expressionResultType = .doubleAttributeType

        pedido.resultType = .dictionaryResultType
        pedido.propertiesToGroupBy = ["vendedor.nombre"]
        pedido.propertiesToFetch = ["vendedor.nombre", suma]

        let filas = (try? contexto.fetch(pedido)) ?? []
        return filas
            .map { (nombre: $0["vendedor.nombre"] as? String ?? "", monto: ($0["monto"] as? NSNumber)?.doubleValue ?? 0) }
            .sorted { $0.monto > $1.monto }
    }

    /// Productos con stock bajo (5 o menos).
    static func stockBajo(en contexto: NSManagedObjectContext) -> [Producto] {
        let pedido = Producto.fetchRequest()
        pedido.predicate = NSPredicate(format: "stock <= %d", 5)
        pedido.sortDescriptors = [NSSortDescriptor(key: "stock", ascending: true)]
        return (try? contexto.fetch(pedido)) ?? []
    }
}
