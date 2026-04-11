//
//  LocalizationManager.swift
//  VitalPathAI
//
//  Multi-language Support for 6 Languages
//  EN, MY, TH, ZH, JA, KO
//

import Foundation

enum SupportedLanguage: String, CaseIterable, Codable {
    case english = "en"
    case myanmar = "my"
    case thai = "th"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .myanmar: return "မြန်မာ"
        case .thai: return "ไทย"
        case .chinese: return "中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }
    
    var flagEmoji: String {
        switch self {
        case .english: return "🇺🇸"
        case .myanmar: return "🇲🇲"
        case .thai: return "🇹🇭"
        case .chinese: return "🇨🇳"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        }
    }
}

@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()
    
    var currentLanguage: SupportedLanguage = .english
    var isRTL: Bool = false
    
    private let userDefaultsKey = "vitalpath_preferred_language"
    
    init() {
        loadSavedLanguage()
    }
    
    /// Load saved language preference
    func loadSavedLanguage() {
        if let savedCode = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = SupportedLanguage(rawValue: savedCode) {
            currentLanguage = language
        } else {
            // Detect system language
            detectSystemLanguage()
        }
    }
    
    /// Save language preference
    func saveLanguage(_ language: SupportedLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: userDefaultsKey)
    }
    
    /// Detect and set system language
    private func detectSystemLanguage() {
        let preferredLanguages = Locale.preferredLanguages
        
        for language in preferredLanguages {
            let langCode = (language as NSString).substring(to: 2)
            
            if let supported = SupportedLanguage(rawValue: langCode) {
                currentLanguage = supported
                return
            }
        }
        
        // Default to English
        currentLanguage = .english
    }
    
    /// Get localized string for key
    func localized(_ key: String, comment: String = "") -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: comment)
        }
        
        return NSLocalizedString(key, tableName: nil, bundle: bundle, comment: comment)
    }
    
    /// Get localized wellness tip for category
    func getWellnessTip(category: WellnessTipCategory) -> String {
        let tips: [WellnessTipCategory: [SupportedLanguage: String]] = [
            .stress: [
                .english: "Try the 4-7-8 breathing technique: Inhale for 4 counts, hold for 7, exhale for 8.",
                .myanmar: "၄-၇-၈ အသက်ရှူလေ့ကျင့်ခန်းကို စမ်းကြည့်ပါ။",
                .thai: "ลองเทคนิคการหายใจ 4-7-8: หายใจเข้า 4 นับ กลั้นไว้ 7 หายใจออก 8",
                .chinese: "尝试 4-7-8 呼吸法：吸气 4 秒，屏息 7 秒，呼气 8 秒。",
                .japanese: "4-7-8 呼吸法を試しましょう：4 つ数えて吸い、7 つ数えて止め、8 つ数えて吐きます。",
                .korean: "4-7-8 호흡법을 시도해보세요: 4 초간 들이마시고, 7 초간 멈추고, 8 초간 내쉽니다."
            ],
            .sleep: [
                .english: "Maintain a consistent bedtime routine and limit screen time 1 hour before bed.",
                .myanmar: "ညအိပ်ချိန်မှန်မှန်နေပါ၊ အိပ်ရာမဝင်ခင် ၁ နာရီအလိုတွင် ဖုန်းကြည့်ခြင်းကို ရှောင်ပါ။",
                .thai: "รักษาเวลานอนให้สม่ำเสมอ และจำกัดการใช้หน้าจอก่อนนอน 1 ชั่วโมง",
                .chinese: "保持规律的睡眠时间，睡前 1 小时避免使用电子设备。",
                .japanese: "就寝時間を一定に保ち、寝る 1 時間前から画面を見るのを控えましょう。",
                .korean: "규칙적인 수면 일정을 유지하고, 잠들기 1 시간 전에는 화면 사용을 자제하세요."
            ],
            .nutrition: [
                .english: "A balanced plate includes: ½ vegetables, ¼ protein, ¼ whole grains.",
                .myanmar: "မျှတသော အစားအစာတွင်: ထက်ဝက်ဟင်းသီးဟင်းရွက်၊ လေးပုံတစ်ပုံပရိုတင်း၊ လေးပုံတစ်ပုံကောက်နှံများ ပါဝင်သည်။",
                .thai: "จานอาหารที่สมดุลประกอบด้วย: ผัก ½ โปรตีน ¼ ธัญพืชเต็มเมล็ด ¼",
                .chinese: "均衡饮食包括：一半蔬菜，四分之一蛋白质，四分之一全谷物。",
                .japanese: "バランスの取れた食事は：野菜半分、タンパク質 4 分の 1、全粒穀物 4 分の 1。",
                .korean: "균형 잡힌 식사는: 채소 절반, 단백질 4 분의 1, 전곡류 4 분의 1."
            ],
            .movement: [
                .english: "Even 10 minutes of movement can boost your mood. Try a short walk or stretching.",
                .myanmar: "၁၀ မိနစ်ခန့် လှုပ်ရှားမှုကပင် စိတ်ဓာတ်ကို ကောင်းမွန်စေနိုင်သည်။",
                .thai: "การเคลื่อนไหวเพียง 10 นาทีก็สามารถปรับปรุงอารมณ์ของคุณได้",
                .chinese: "即使只有 10 分钟的运动也能改善心情。试试散步或伸展运动。",
                .japanese: "たった 10 分の運動でも気分を向上できます。短い散歩やストレッチを試しましょう。",
                .korean: "단 10 분의 운동이라도 기분을 좋게 할 수 있습니다. 짧은 산책이나 스트레칭을 해보세요."
            ]
        ]
        
        return tips[category]?[currentLanguage] ?? tips[category]?[.english] ?? ""
    }
    
    /// Get crisis helpline info for current region
    func getCrisisHelpline() -> CrisisHelplineInfo {
        switch currentLanguage {
        case .english:
            return CrisisHelplineInfo(region: "US", number: "988", name: "Suicide & Crisis Lifeline", available: "24/7")
        case .myanmar:
            return CrisisHelplineInfo(region: "MM", number: "+95-1-234567", name: "Myanmar Mental Health Support", available: "Mon-Fri 9AM-5PM")
        case .thai:
            return CrisisHelplineInfo(region: "TH", number: "1323", name: "Thai Mental Health Hotline", available: "24/7")
        case .chinese:
            return CrisisHelplineInfo(region: "CN", number: "400-161-9995", name: "Hope 24 Hotline", available: "24/7")
        case .japanese:
            return CrisisHelplineInfo(region: "JP", number: "03-5286-1165", name: "Inochi-no-Denwa", available: "24/7")
        case .korean:
            return CrisisHelplineInfo(region: "KR", number: "109", name: "Korea Suicide Prevention Center", available: "24/7")
        }
    }
}

enum WellnessTipCategory: String, CaseIterable {
    case stress
    case sleep
    case nutrition
    case movement
}

struct CrisisHelplineInfo {
    let region: String
    let number: String
    let name: String
    let available: String
}
