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
}
