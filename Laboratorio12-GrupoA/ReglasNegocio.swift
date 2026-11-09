//
//  ReglasNegocio.swift
//  Laboratorio12-GrupoA
//
//  Reglas del caso Ventas (Grupo A).
//

import Foundation

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
