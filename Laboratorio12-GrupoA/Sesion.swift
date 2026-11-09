//
//  Sesion.swift
//  Laboratorio12-GrupoA
//
//  Sesión compartida: una clase con un único objeto (static let)
//  y una variable con el usuario actual.
//

import Foundation

enum Rol {
    static let vendedor = "Vendedor"
    static let supervisor = "Supervisor"
}

final class Sesion {
    static let compartida = Sesion()

    var usuarioActual: Usuario?

    private init() {}

    var esSupervisor: Bool {
        usuarioActual?.rol == Rol.supervisor
    }
}
