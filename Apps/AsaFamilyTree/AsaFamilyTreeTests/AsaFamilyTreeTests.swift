import Testing
import SwiftUI
@testable import AsaFamilyTree

@Suite("AsaFamilyTree App Tests")
struct AsaFamilyTreeTests {

    @Test("Tab enum has all required cases")
    func testTabCases() {
        let tabs: [Tab] = [.tree, .members, .statistics, .settings]
        #expect(tabs.count == 4)
    }

    @Test("RelationType enum has correct display names")
    func testRelationTypeDisplayNames() {
        #expect(RelationType.parent.displayName == "親")
        #expect(RelationType.child.displayName == "子")
        #expect(RelationType.spouse.displayName == "配偶者")
    }

    @Test("ExportFormat enum has correct display names")
    func testExportFormatDisplayNames() {
        #expect(ExportFormat.png.displayName == "PNG画像")
        #expect(ExportFormat.pdf.displayName == "PDF")
    }
}
