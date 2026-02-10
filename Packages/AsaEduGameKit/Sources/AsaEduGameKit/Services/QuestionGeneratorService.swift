import Foundation

// MARK: - 問題生成サービス

/// 4モード全ての問題を生成するサービス
/// 各モード・難易度に応じた適切な問題を動的に生成
public final class QuestionGeneratorService: QuestionGenerating {

    // MARK: - Init

    public init() {}

    // MARK: - QuestionGenerating

    /// 指定モード・難易度で問題セットを生成
    public func generateQuestions(
        mode: GameMode,
        difficulty: DifficultyLevel,
        count: Int
    ) -> [GameQuestion] {
        let types = questionTypes(for: mode, difficulty: difficulty)
        return (0 ..< count).map { _ in
            let type = types.randomElement()!
            return generateQuestion(type: type, difficulty: difficulty)
        }
    }

    /// 単一問題を生成
    public func generateQuestion(
        type: QuestionType,
        difficulty: DifficultyLevel
    ) -> GameQuestion {
        switch type {
        case .addition:
            return generateAddition(difficulty: difficulty)
        case .subtraction:
            return generateSubtraction(difficulty: difficulty)
        case .comparison:
            return generateComparison(difficulty: difficulty)
        case .fillInBlank:
            return generateFillInBlank(difficulty: difficulty)
        case .hiraganaReading:
            return generateHiraganaReading(difficulty: difficulty)
        case .hiraganaMatching:
            return generateHiraganaMatching(difficulty: difficulty)
        case .hiraganaWriting:
            return generateHiraganaWriting(difficulty: difficulty)
        case .shapeIdentification:
            return generateShapeIdentification(difficulty: difficulty)
        case .shapePattern:
            return generateShapePattern(difficulty: difficulty)
        case .shapeCombination:
            return generateShapeCombination(difficulty: difficulty)
        case .oddOneOut:
            return generateOddOneOut(difficulty: difficulty)
        case .sequenceOrder:
            return generateSequenceOrder(difficulty: difficulty)
        case .patternCompletion:
            return generatePatternCompletion(difficulty: difficulty)
        }
    }

    // MARK: - ヘルパー

    /// モード・難易度で使用可能な問題タイプを取得
    private func questionTypes(for mode: GameMode, difficulty: DifficultyLevel) -> [QuestionType] {
        switch mode {
        case .mathQuiz:
            switch difficulty {
            case .easy:
                return [.addition, .subtraction]
            case .normal:
                return [.addition, .subtraction, .comparison]
            case .hard:
                return [.addition, .subtraction, .comparison, .fillInBlank]
            }
        case .hiraganaPractice:
            switch difficulty {
            case .easy:
                return [.hiraganaReading, .hiraganaMatching]
            case .normal:
                return [.hiraganaReading, .hiraganaMatching]
            case .hard:
                return [.hiraganaReading, .hiraganaMatching, .hiraganaWriting]
            }
        case .shapePuzzle:
            switch difficulty {
            case .easy:
                return [.shapeIdentification]
            case .normal:
                return [.shapeIdentification, .shapePattern]
            case .hard:
                return [.shapeIdentification, .shapePattern, .shapeCombination]
            }
        case .logicGame:
            switch difficulty {
            case .easy:
                return [.oddOneOut]
            case .normal:
                return [.oddOneOut, .sequenceOrder]
            case .hard:
                return [.oddOneOut, .sequenceOrder, .patternCompletion]
            }
        }
    }

    /// 選択肢をシャッフルして返す（正解を含む4択）
    private func shuffledOptions(correct: String, distractors: [String]) -> [String] {
        var options = [correct] + Array(distractors.prefix(3))
        // 足りない場合は埋める
        while options.count < 4 {
            options.append("?")
        }
        options.shuffle()
        return options
    }

    // MARK: - 算数問題生成

    /// たしざん問題を生成
    private func generateAddition(difficulty: DifficultyLevel) -> GameQuestion {
        let maxNum: Int
        switch difficulty {
        case .easy: maxNum = 5
        case .normal: maxNum = 10
        case .hard: maxNum = 20
        }
        let a = Int.random(in: 1 ... maxNum)
        let b = Int.random(in: 1 ... maxNum)
        let answer = a + b
        let answerStr = "\(answer)"

        // ダミー選択肢の生成（正解の前後から）
        var distractors: Set<String> = []
        while distractors.count < 3 {
            let offset = Int.random(in: 1 ... 5) * (Bool.random() ? 1 : -1)
            let dummy = answer + offset
            if dummy > 0 && dummy != answer {
                distractors.insert("\(dummy)")
            }
        }

        return GameQuestion(
            questionType: .addition,
            questionText: "\(a) + \(b) = ?",
            options: shuffledOptions(correct: answerStr, distractors: Array(distractors)),
            correctAnswer: answerStr,
            hint: "ゆびでかぞえてみよう！"
        )
    }

    /// ひきざん問題を生成
    private func generateSubtraction(difficulty: DifficultyLevel) -> GameQuestion {
        let maxNum: Int
        switch difficulty {
        case .easy: maxNum = 5
        case .normal: maxNum = 10
        case .hard: maxNum = 20
        }
        // 答えが負にならないように大きい方を先に
        let a = Int.random(in: 2 ... maxNum)
        let b = Int.random(in: 1 ..< a)
        let answer = a - b
        let answerStr = "\(answer)"

        var distractors: Set<String> = []
        while distractors.count < 3 {
            let offset = Int.random(in: 1 ... 5) * (Bool.random() ? 1 : -1)
            let dummy = answer + offset
            if dummy >= 0 && dummy != answer {
                distractors.insert("\(dummy)")
            }
        }

        return GameQuestion(
            questionType: .subtraction,
            questionText: "\(a) - \(b) = ?",
            options: shuffledOptions(correct: answerStr, distractors: Array(distractors)),
            correctAnswer: answerStr,
            hint: "\(a)こから\(b)こへらすと？"
        )
    }

    /// くらべっこ問題を生成
    private func generateComparison(difficulty: DifficultyLevel) -> GameQuestion {
        let maxNum: Int
        switch difficulty {
        case .easy: maxNum = 10
        case .normal: maxNum = 20
        case .hard: maxNum = 50
        }
        var a = Int.random(in: 1 ... maxNum)
        var b = Int.random(in: 1 ... maxNum)
        // 同じ数にならないようにする
        while a == b {
            b = Int.random(in: 1 ... maxNum)
        }
        let correctAnswer = a > b ? "\(a)" : "\(b)"

        return GameQuestion(
            questionType: .comparison,
            questionText: "\(a) と \(b)、おおきいのはどっち？",
            options: shuffledOptions(correct: correctAnswer, distractors: ["\(min(a, b))", "\(a + b)", "\(abs(a - b))"]),
            correctAnswer: correctAnswer,
            hint: "かずのおおきさをくらべよう！"
        )
    }

    /// あなうめ問題を生成
    private func generateFillInBlank(difficulty: DifficultyLevel) -> GameQuestion {
        let maxNum: Int
        switch difficulty {
        case .easy: maxNum = 5
        case .normal: maxNum = 10
        case .hard: maxNum = 20
        }
        let isAddition = Bool.random()
        let a = Int.random(in: 1 ... maxNum)
        let b = Int.random(in: 1 ... maxNum)

        let questionText: String
        let answer: Int
        if isAddition {
            answer = a
            questionText = "? + \(b) = \(a + b)"
        } else {
            let total = a + b
            answer = b
            questionText = "\(total) - ? = \(a)"
        }
        let answerStr = "\(answer)"

        var distractors: Set<String> = []
        while distractors.count < 3 {
            let offset = Int.random(in: 1 ... 4) * (Bool.random() ? 1 : -1)
            let dummy = answer + offset
            if dummy > 0 && dummy != answer {
                distractors.insert("\(dummy)")
            }
        }

        return GameQuestion(
            questionType: .fillInBlank,
            questionText: questionText,
            options: shuffledOptions(correct: answerStr, distractors: Array(distractors)),
            correctAnswer: answerStr,
            hint: "?にはいるかずはなにかな？"
        )
    }

    // MARK: - ひらがな問題生成

    /// ひらがな文字セット定義
    private static let hiraganaAToSa: [(kana: String, word: String, reading: String)] = [
        ("あ", "あめ", "あめ"), ("い", "いぬ", "いぬ"), ("う", "うし", "うし"),
        ("え", "えんぴつ", "えんぴつ"), ("お", "おにぎり", "おにぎり"),
        ("か", "かめ", "かめ"), ("き", "きつね", "きつね"), ("く", "くま", "くま"),
        ("け", "けーき", "けーき"), ("こ", "こねこ", "こねこ"),
        ("さ", "さかな", "さかな"), ("し", "しか", "しか"), ("す", "すいか", "すいか"),
        ("せ", "せみ", "せみ"), ("そ", "そら", "そら"),
    ]

    private static let hiraganaTaToHa: [(kana: String, word: String, reading: String)] = [
        ("た", "たいこ", "たいこ"), ("ち", "ちず", "ちず"), ("つ", "つき", "つき"),
        ("て", "てがみ", "てがみ"), ("と", "とけい", "とけい"),
        ("な", "なす", "なす"), ("に", "にじ", "にじ"), ("ぬ", "ぬいぐるみ", "ぬいぐるみ"),
        ("ね", "ねこ", "ねこ"), ("の", "のり", "のり"),
        ("は", "はな", "はな"), ("ひ", "ひこうき", "ひこうき"), ("ふ", "ふね", "ふね"),
        ("へ", "へび", "へび"), ("ほ", "ほし", "ほし"),
    ]

    private static let hiraganaAll: [(kana: String, word: String, reading: String)] = {
        var all = hiraganaAToSa + hiraganaTaToHa
        // ま〜わ行 + ん + 濁音
        all += [
            ("ま", "まど", "まど"), ("み", "みかん", "みかん"), ("む", "むし", "むし"),
            ("め", "めがね", "めがね"), ("も", "もも", "もも"),
            ("や", "やま", "やま"), ("ゆ", "ゆき", "ゆき"), ("よ", "よる", "よる"),
            ("ら", "らいおん", "らいおん"), ("り", "りんご", "りんご"), ("る", "るすばん", "るすばん"),
            ("れ", "れもん", "れもん"), ("ろ", "ろけっと", "ろけっと"),
            ("わ", "わに", "わに"), ("を", "をかし", "をかし"), ("ん", "しんかんせん", "しんかんせん"),
            // 濁音
            ("が", "がっこう", "がっこう"), ("ぎ", "ぎゅうにゅう", "ぎゅうにゅう"),
            ("ぐ", "ぐみ", "ぐみ"), ("げ", "げんき", "げんき"), ("ご", "ごはん", "ごはん"),
            ("ざ", "ざりがに", "ざりがに"), ("じ", "じてんしゃ", "じてんしゃ"),
            ("ず", "ずぼん", "ずぼん"), ("ぜ", "ぜりー", "ぜりー"), ("ぞ", "ぞう", "ぞう"),
            ("だ", "だいこん", "だいこん"), ("ぢ", "ちぢみ", "ちぢみ"),
            ("づ", "つづき", "つづき"), ("で", "でんわ", "でんわ"), ("ど", "どんぐり", "どんぐり"),
            ("ば", "ばなな", "ばなな"), ("び", "びん", "びん"),
            ("ぶ", "ぶどう", "ぶどう"), ("べ", "べんきょう", "べんきょう"), ("ぼ", "ぼうし", "ぼうし"),
            ("ぱ", "ぱん", "ぱん"), ("ぴ", "ぴあの", "ぴあの"),
            ("ぷ", "ぷりん", "ぷりん"), ("ぺ", "ぺんぎん", "ぺんぎん"), ("ぽ", "ぽすと", "ぽすと"),
        ]
        return all
    }()

    /// 難易度に応じたひらがなセットを取得
    private func hiraganaSet(for difficulty: DifficultyLevel) -> [(kana: String, word: String, reading: String)] {
        switch difficulty {
        case .easy:
            return Self.hiraganaAToSa
        case .normal:
            return Self.hiraganaAToSa + Self.hiraganaTaToHa
        case .hard:
            return Self.hiraganaAll
        }
    }

    /// よみかた問題を生成
    private func generateHiraganaReading(difficulty: DifficultyLevel) -> GameQuestion {
        let set = hiraganaSet(for: difficulty)
        let target = set.randomElement()!

        // ダミーの文字を取得
        var distractors: [String] = []
        var pool = set.filter { $0.kana != target.kana }
        pool.shuffle()
        distractors = Array(pool.prefix(3).map(\.kana))

        return GameQuestion(
            questionType: .hiraganaReading,
            questionText: "「\(target.word)」のさいしょのもじは？",
            options: shuffledOptions(correct: target.kana, distractors: distractors),
            correctAnswer: target.kana,
            hint: "「\(target.word)」をゆっくりよんでみよう！"
        )
    }

    /// くみあわせ問題を生成
    private func generateHiraganaMatching(difficulty: DifficultyLevel) -> GameQuestion {
        let set = hiraganaSet(for: difficulty)
        let target = set.randomElement()!

        // ダミーの単語を取得
        var distractors: [String] = []
        var pool = set.filter { $0.kana != target.kana }
        pool.shuffle()
        distractors = Array(pool.prefix(3).map(\.word))

        return GameQuestion(
            questionType: .hiraganaMatching,
            questionText: "「\(target.kana)」ではじまることばは？",
            options: shuffledOptions(correct: target.word, distractors: distractors),
            correctAnswer: target.word,
            hint: "「\(target.kana)」からはじまるものをさがそう！"
        )
    }

    /// かきかた問題を生成（選択肢式）
    private func generateHiraganaWriting(difficulty: DifficultyLevel) -> GameQuestion {
        let set = hiraganaSet(for: difficulty)
        let target = set.randomElement()!

        // 似た形の文字をダミーに
        var distractors: [String] = []
        var pool = set.filter { $0.kana != target.kana }
        pool.shuffle()
        distractors = Array(pool.prefix(3).map(\.kana))

        return GameQuestion(
            questionType: .hiraganaWriting,
            questionText: "「\(target.word)」のさいしょのもじをかこう！",
            options: shuffledOptions(correct: target.kana, distractors: distractors),
            correctAnswer: target.kana,
            hint: "おてほんをよくみてね！"
        )
    }

    // MARK: - 図形問題生成

    /// 基本図形データ
    private static let basicShapes: [(name: String, emoji: String, sides: Int)] = [
        ("まる", "⭕", 0),
        ("さんかく", "🔺", 3),
        ("しかく", "🟦", 4),
    ]

    private static let extendedShapes: [(name: String, emoji: String, sides: Int)] = [
        ("まる", "⭕", 0),
        ("さんかく", "🔺", 3),
        ("しかく", "🟦", 4),
        ("ほし", "⭐", 5),
        ("ハート", "❤️", 0),
        ("ひしがた", "🔷", 4),
    ]

    /// なにのかたち？問題を生成
    private func generateShapeIdentification(difficulty: DifficultyLevel) -> GameQuestion {
        let shapes: [(name: String, emoji: String, sides: Int)]
        switch difficulty {
        case .easy:
            shapes = Self.basicShapes
        case .normal, .hard:
            shapes = Self.extendedShapes
        }

        let target = shapes.randomElement()!
        var distractors = shapes.filter { $0.name != target.name }.shuffled()
        let distractorNames = Array(distractors.prefix(3).map(\.name))

        return GameQuestion(
            questionType: .shapeIdentification,
            questionText: "\(target.emoji) このかたちはなに？",
            options: shuffledOptions(correct: target.name, distractors: distractorNames),
            correctAnswer: target.name,
            imageName: nil,
            hint: "かたちをよくみてね！"
        )
    }

    /// パターン問題を生成
    private func generateShapePattern(difficulty: DifficultyLevel) -> GameQuestion {
        let patterns: [(sequence: String, answer: String, options: [String])]
        switch difficulty {
        case .easy, .normal:
            patterns = [
                ("⭕🔺⭕🔺⭕?", "🔺", ["⭕", "🟦", "⭐"]),
                ("🟦🟦⭕🟦🟦?", "⭕", ["🟦", "🔺", "⭐"]),
                ("🔺⭕⭕🔺⭕?", "⭕", ["🔺", "🟦", "⭐"]),
                ("⭕⭕🔺⭕⭕?", "🔺", ["⭕", "🟦", "⭐"]),
            ]
        case .hard:
            patterns = [
                ("⭕🔺🟦⭕🔺?", "🟦", ["⭕", "🔺", "⭐"]),
                ("⭐⭕⭐⭕⭐?", "⭕", ["⭐", "🔺", "🟦"]),
                ("🔺🟦⭕🔺🟦?", "⭕", ["🔺", "🟦", "⭐"]),
                ("❤️⭐❤️⭐❤️?", "⭐", ["❤️", "🔺", "⭕"]),
            ]
        }

        let pattern = patterns.randomElement()!

        return GameQuestion(
            questionType: .shapePattern,
            questionText: "つぎにくるかたちは？\n\(pattern.sequence)",
            options: shuffledOptions(correct: pattern.answer, distractors: pattern.options),
            correctAnswer: pattern.answer,
            hint: "パターンをみつけよう！"
        )
    }

    /// くみあわせ問題を生成
    private func generateShapeCombination(difficulty: DifficultyLevel) -> GameQuestion {
        let combinations: [(question: String, answer: String, distractors: [String])]
        switch difficulty {
        case .easy, .normal:
            combinations = [
                ("🔺をさかさまにすると？", "🔻", ["🔺", "🟦", "⭕"]),
                ("⭕をはんぶんにすると？", "はんえん", ["まる", "さんかく", "しかく"]),
            ]
        case .hard:
            combinations = [
                ("🔺と🔻をあわせると？", "ひしがた", ["さんかく", "しかく", "まる"]),
                ("🟦を2つならべると？", "ながしかく", ["しかく", "まる", "さんかく"]),
                ("⭕を2つかさねると？", "にじゅうまる", ["まる", "しかく", "さんかく"]),
            ]
        }

        let combo = combinations.randomElement()!

        return GameQuestion(
            questionType: .shapeCombination,
            questionText: combo.question,
            options: shuffledOptions(correct: combo.answer, distractors: combo.distractors),
            correctAnswer: combo.answer,
            hint: "あたまのなかでかたちをうごかしてみよう！"
        )
    }

    // MARK: - 論理問題生成

    /// なかまはずれ問題を生成
    private func generateOddOneOut(difficulty: DifficultyLevel) -> GameQuestion {
        let groups: [(items: [String], oddOne: String, category: String)]
        switch difficulty {
        case .easy:
            groups = [
                (["🍎", "🍊", "🍌", "🐶"], "🐶", "くだもの"),
                (["🐱", "🐶", "🐰", "🚗"], "🚗", "どうぶつ"),
                (["🔴", "🟢", "🔵", "⭐"], "⭐", "まるいもの"),
            ]
        case .normal:
            groups = [
                (["🍎", "🍊", "🥕", "🍌"], "🥕", "くだもの"),
                (["✈️", "🚗", "🚃", "🐱"], "🐱", "のりもの"),
                (["🌸", "🌻", "🌹", "🍎"], "🍎", "おはな"),
                (["1", "3", "5", "4"], "4", "きすう"),
            ]
        case .hard:
            groups = [
                (["🍎", "🍒", "🍓", "🍊"], "🍊", "あかいくだもの"),
                (["2", "4", "6", "9"], "9", "ぐうすう"),
                (["あ", "い", "う", "か"], "か", "あぎょう"),
                (["⭕", "🔺", "🟦", "🔴"], "🔴", "かたち"),
            ]
        }

        let group = groups.randomElement()!

        return GameQuestion(
            questionType: .oddOneOut,
            questionText: "なかまはずれはどれ？\n\(group.items.joined(separator: "  "))",
            options: group.items.shuffled(),
            correctAnswer: group.oddOne,
            hint: "おなじなかまをさがしてみよう！"
        )
    }

    /// じゅんばん問題を生成
    private func generateSequenceOrder(difficulty: DifficultyLevel) -> GameQuestion {
        let sequences: [(question: String, answer: String, distractors: [String])]
        switch difficulty {
        case .easy, .normal:
            sequences = [
                ("1, 2, 3, ?", "4", ["5", "3", "6"]),
                ("2, 4, 6, ?", "8", ["7", "10", "5"]),
                ("あ, い, う, ?", "え", ["お", "か", "き"]),
                ("10, 20, 30, ?", "40", ["50", "35", "25"]),
            ]
        case .hard:
            sequences = [
                ("1, 3, 5, 7, ?", "9", ["8", "10", "11"]),
                ("2, 4, 8, 16, ?", "32", ["24", "20", "18"]),
                ("1, 1, 2, 3, 5, ?", "8", ["6", "7", "10"]),
                ("100, 90, 80, ?", "70", ["60", "75", "85"]),
            ]
        }

        let seq = sequences.randomElement()!

        return GameQuestion(
            questionType: .sequenceOrder,
            questionText: "つぎのかずは？\n\(seq.question)",
            options: shuffledOptions(correct: seq.answer, distractors: seq.distractors),
            correctAnswer: seq.answer,
            hint: "かずのならびをよくみよう！"
        )
    }

    /// パターン完成問題を生成
    private func generatePatternCompletion(difficulty: DifficultyLevel) -> GameQuestion {
        let patterns: [(question: String, answer: String, distractors: [String])]
        switch difficulty {
        case .easy, .normal:
            patterns = [
                ("🔴🔵🔴🔵🔴?", "🔵", ["🔴", "🟢", "🟡"]),
                ("⬆️➡️⬇️⬅️⬆️?", "➡️", ["⬇️", "⬅️", "⬆️"]),
                ("😊😢😊😢😊?", "😢", ["😊", "😡", "😴"]),
            ]
        case .hard:
            patterns = [
                ("🔴🔵🟢🔴🔵?", "🟢", ["🔴", "🔵", "🟡"]),
                ("⭐⭐🌙⭐⭐?", "🌙", ["⭐", "☀️", "🌈"]),
                ("🍎🍊🍌🍎🍊?", "🍌", ["🍎", "🍊", "🍇"]),
                ("1A2B3?", "C", ["D", "4", "A"]),
            ]
        }

        let pattern = patterns.randomElement()!

        return GameQuestion(
            questionType: .patternCompletion,
            questionText: "?にはいるものは？\n\(pattern.question)",
            options: shuffledOptions(correct: pattern.answer, distractors: pattern.distractors),
            correctAnswer: pattern.answer,
            hint: "くりかえしのきまりをみつけよう！"
        )
    }
}
