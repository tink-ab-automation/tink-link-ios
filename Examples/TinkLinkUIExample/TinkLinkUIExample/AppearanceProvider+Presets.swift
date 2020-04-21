import UIKit
import TinkLinkUI

extension AppearanceProvider {

    private static func makeProvider(folderName: String) -> AppearanceProvider {
        let color = ColorProvider()
        color.background = UIColor(named: "\(folderName)/Background")!
        color.secondaryBackground = UIColor(named: "\(folderName)/SecondaryBackground")!
        color.groupedBackground = UIColor(named: "\(folderName)/GroupedBackground")!
        color.secondaryGroupedBackground = UIColor(named: "\(folderName)/GroupedSecondaryBackground")!
        color.label = UIColor(named: "\(folderName)/Label")!
        color.secondaryLabel = UIColor(named: "\(folderName)/SecondaryLabel")!
        color.separator = UIColor(named: "\(folderName)/Separator")!
        color.accent = UIColor(named: "\(folderName)/Accent")!
        color.warning = UIColor(named: "\(folderName)/Uncategorized")!
        color.critical = .red
        return AppearanceProvider(colors: color)
    }
    
    private static func makeProviderWithFonts(folderName: String, regular: String, bold: String) -> AppearanceProvider {
        let color = ColorProvider()
        let font = FontProvider()
        color.background = UIColor(named: "\(folderName)/Background")!
        color.secondaryBackground = UIColor(named: "\(folderName)/SecondaryBackground")!
        color.groupedBackground = UIColor(named: "\(folderName)/GroupedBackground")!
        color.secondaryGroupedBackground = UIColor(named: "\(folderName)/GroupedSecondaryBackground")!
        color.label = UIColor(named: "\(folderName)/Label")!
        color.secondaryLabel = UIColor(named: "\(folderName)/SecondaryLabel")!
        color.separator = UIColor(named: "\(folderName)/Separator")!
        color.accent = UIColor(named: "\(folderName)/Accent")!
        color.warning = UIColor(named: "\(folderName)/Uncategorized")!
        color.critical = .red
        font.regularFont = .custom("\(regular)")
        font.boldFont = .custom("\(bold)")
        return AppearanceProvider(colors: color, fonts: font)
            
    }

    static var darkGreen: AppearanceProvider = makeProvider(folderName: "DarkGreen")
    static var blue: AppearanceProvider = makeProvider(folderName: "Blue")
    static var purple: AppearanceProvider = makeProvider(folderName: "Purple")
    static var chewinggum: AppearanceProvider = makeProviderWithFonts(folderName: "Chewinggum", regular: "Avenir-Book", bold: "Avenir-Black")
    static var strict: AppearanceProvider = makeProviderWithFonts(folderName: "Strict", regular: "GillSans", bold: "GillSans-SemiBold")
}
