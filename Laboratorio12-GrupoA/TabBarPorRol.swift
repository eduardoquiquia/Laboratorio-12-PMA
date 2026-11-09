//
//  TabBarPorRol.swift
//  Laboratorio12-GrupoA
//
//  UITabBarController cuyas pestañas dependen del rol de la sesión.
//    Vendedor:   Productos, Clientes, Venta, Mis ventas, Cuenta
//    Supervisor: Resumen, Ventas, Productos, Clientes, Cuenta
//

import UIKit

enum TabBarPorRol {

    static func crear(para usuario: Usuario) -> UITabBarController {
        let pestanas: [UIViewController]
        if usuario.rol == Rol.supervisor {
            pestanas = [
                envolver(pendiente("Resumen"), "Resumen", "chart.bar.fill"),
                envolver(pendiente("Ventas del equipo"), "Ventas", "list.bullet.rectangle.fill"),
                envolver(ProductosViewController(), "Productos", "shippingbox.fill"),
                envolver(ClientesViewController(), "Clientes", "person.2.fill"),
                envolver(CuentaViewController(), "Cuenta", "person.crop.circle.fill")
            ]
        } else {
            pestanas = [
                envolver(ProductosViewController(), "Productos", "shippingbox.fill"),
                envolver(ClientesViewController(), "Clientes", "person.2.fill"),
                envolver(pendiente("Nueva venta"), "Venta", "cart.fill"),
                envolver(pendiente("Mis ventas"), "Mis ventas", "list.bullet.rectangle.fill"),
                envolver(CuentaViewController(), "Cuenta", "person.crop.circle.fill")
            ]
        }
        let tab = UITabBarController()
        tab.viewControllers = pestanas
        return tab
    }

    private static func envolver(_ pantalla: UIViewController, _ titulo: String, _ icono: String) -> UINavigationController {
        let nav = UINavigationController(rootViewController: pantalla)
        nav.tabBarItem = UITabBarItem(title: titulo, image: UIImage(systemName: icono), tag: 0)
        return nav
    }

    /// Pantalla vacía (solo título) para las pestañas que se implementan en etapas posteriores.
    private static func pendiente(_ titulo: String) -> UIViewController {
        let pantalla = UIViewController()
        pantalla.title = titulo
        pantalla.view.backgroundColor = .systemGroupedBackground
        return pantalla
    }
}
