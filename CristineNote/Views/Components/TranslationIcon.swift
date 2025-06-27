import SwiftUI

struct TranslationIcon: View {
    let size: CGFloat
    
    init(size: CGFloat = 12) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Google翻译风格的蓝色背景
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(Color.blue)
                .frame(width: size + 2, height: size + 2)
            
            // 自定义翻译图标 - 类似Google翻译的设计
            ZStack {
                // 左侧字母 A (英文)
                Text("A")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: -size * 0.2, y: -size * 0.1)
                
                // 右侧中文字符
                Text("文")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: size * 0.2, y: size * 0.1)
            }
        }
    }
}

struct CustomTranslationIcon: View {
    let size: CGFloat
    
    init(size: CGFloat = 12) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // 背景圆形
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: size + 4, height: size + 4)
            
            // 自定义翻译图标 - 类似Google翻译的设计
            ZStack {
                // 左侧字母 A
                Text("A")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(.blue)
                    .offset(x: -size * 0.15, y: -size * 0.1)
                
                // 右侧中文字符
                Text("文")
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundColor(.blue)
                    .offset(x: size * 0.15, y: size * 0.1)
                
                // 中间的箭头
                Image(systemName: "arrow.right")
                    .font(.system(size: size * 0.3, weight: .medium))
                    .foregroundColor(.blue.opacity(0.7))
                    .rotationEffect(.degrees(15))
            }
        }
    }
}

// 预览
struct TranslationIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                TranslationIcon(size: 12)
                TranslationIcon(size: 16)
                TranslationIcon(size: 20)
            }
            
            HStack(spacing: 10) {
                CustomTranslationIcon(size: 12)
                CustomTranslationIcon(size: 16)  
                CustomTranslationIcon(size: 20)
            }
        }
        .padding()
    }
} 