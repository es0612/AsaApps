import Testing
@testable import AsaFamilyTreeKit

@Suite("AsaFamilyTreeKit Tests")
struct AsaFamilyTreeKitTests {

    @Test("Gender enum has correct display names")
    func testGenderDisplayNames() {
        #expect(Gender.male.displayName == "男性")
        #expect(Gender.female.displayName == "女性")
        #expect(Gender.other.displayName == "その他")
    }

    @Test("Gender enum has correct raw values")
    func testGenderRawValues() {
        #expect(Gender.male.rawValue == "male")
        #expect(Gender.female.rawValue == "female")
        #expect(Gender.other.rawValue == "other")
    }

    @Test("AgeRange correctly categorizes ages")
    func testAgeRangeFromAge() {
        #expect(AgeRange.from(age: 5) == .under10)
        #expect(AgeRange.from(age: 15) == .teens)
        #expect(AgeRange.from(age: 25) == .twenties)
        #expect(AgeRange.from(age: 35) == .thirties)
        #expect(AgeRange.from(age: 45) == .forties)
        #expect(AgeRange.from(age: 55) == .fifties)
        #expect(AgeRange.from(age: 65) == .sixties)
        #expect(AgeRange.from(age: 75) == .seventies)
        #expect(AgeRange.from(age: 85) == .eighties)
        #expect(AgeRange.from(age: 95) == .ninetyPlus)
    }

    @Test("AgeRange has correct display names")
    func testAgeRangeDisplayNames() {
        #expect(AgeRange.under10.displayName == "0-9歳")
        #expect(AgeRange.twenties.displayName == "20代")
        #expect(AgeRange.ninetyPlus.displayName == "90歳以上")
    }

    @Test("AgeRange sort order is correct")
    func testAgeRangeSortOrder() {
        let ranges = AgeRange.allCases.sorted()
        #expect(ranges.first == .under10)
        #expect(ranges.last == .ninetyPlus)
    }

    @Test("FamilyTreeError has localized descriptions")
    func testFamilyTreeErrorDescriptions() {
        #expect(FamilyTreeError.memberNotFound.errorDescription == "メンバーが見つかりません")
        #expect(FamilyTreeError.treeNotFound.errorDescription == "家系図が見つかりません")
        #expect(FamilyTreeError.circularRelationship.errorDescription == "循環する関係は作成できません（例：自分自身の親になる）")
    }

    @Test("MemberSnapshot correctly captures member data")
    func testMemberSnapshot() {
        let member = FamilyMember(
            firstName: "太郎",
            lastName: "山田",
            gender: .male,
            birthDate: Date(timeIntervalSince1970: 0) // 1970-01-01
        )

        let snapshot = MemberSnapshot(member: member)

        #expect(snapshot.firstName == "太郎")
        #expect(snapshot.lastName == "山田")
        #expect(snapshot.gender == .male)
        #expect(snapshot.fullName == "山田 太郎")
        #expect(snapshot.isAlive == true)
    }
}
