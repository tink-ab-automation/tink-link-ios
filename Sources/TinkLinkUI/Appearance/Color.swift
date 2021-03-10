import UIKit

/// A namespace for custom colors.
enum Color {}

// Shorthands for readability
extension Color {
    static var background: UIColor { Appearance.colorProvider.background }
    static var secondaryBackground: UIColor { Appearance.colorProvider.secondaryBackground }
    static var label: UIColor { Appearance.colorProvider.label }
    static var secondaryLabel: UIColor { Appearance.colorProvider.secondaryLabel }
    static var separator: UIColor { Appearance.colorProvider.separator }
    static var accent: UIColor { Appearance.colorProvider.accent }
    static var accentBackground: UIColor { Appearance.colorProvider.accentBackground }
    static var button: UIColor { Appearance.colorProvider.button }
    static var buttonLabel: UIColor { Appearance.colorProvider.buttonLabel }

    static var warning: UIColor { Appearance.colorProvider.warning }
    static var critical: UIColor { Appearance.colorProvider.critical }

    static var navigationBarBackground: UIColor { Appearance.colorProvider.navigationBarBackground ?? background }
    static var navigationBarButton: UIColor { Appearance.colorProvider.navigationBarButton ?? accent }
    static var navigationBarLabel: UIColor { Appearance.colorProvider.navigationBarLabel ?? label }
}

// Derived colors
extension Color {
    static var highlight: UIColor { accent.withAlphaComponent(0.1) }
    static var warningBackground: UIColor { warning.mixedWith(color: Color.background, factor: 0.8) }
}
