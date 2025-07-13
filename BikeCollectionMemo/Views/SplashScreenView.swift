import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotationAngle = 0.0
    @State private var showTitle = false
    @State private var showSubtitle = false
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // グラデーション背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.3, blue: 0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // バイクアイコンとアニメーション
                    ZStack {
                        // 背景サークル
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 200, height: 200)
                            .scaleEffect(size)
                            .opacity(opacity)
                        
                        // バイクアイコン
                        Image(systemName: "motorcycle")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(rotationAngle))
                            .scaleEffect(size)
                            .opacity(opacity)
                    }
                    
                    VStack(spacing: 10) {
                        // アプリタイトル
                        if showTitle {
                            Text("BikeCollectionMemo")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .transition(.slide.combined(with: .opacity))
                        }
                        
                        // サブタイトル
                        if showSubtitle {
                            Text("愛車の整備記録を簡単管理")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .transition(.slide.combined(with: .opacity))
                        }
                    }
                    
                    // プログレスインジケータ
                    if showSubtitle {
                        HStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color.white.opacity(0.7))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(showTitle ? 1.0 : 0.5)
                                    .animation(
                                        Animation.easeInOut(duration: 0.6)
                                            .repeatForever()
                                            .delay(Double(index) * 0.2),
                                        value: showTitle
                                    )
                            }
                        }
                        .transition(.opacity)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeIn(duration: 1.2)) {
                    self.size = 0.9
                    self.opacity = 1.0
                }
                
                withAnimation(.linear(duration: 2.0)) {
                    self.rotationAngle = 360
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        self.showTitle = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        self.showSubtitle = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct AnimatedSplashView: View {
    @State private var isActive = false
    @State private var showOnboarding = false
    @State private var particles: [Particle] = []
    @State private var showLogo = false
    @State private var logoScale: CGFloat = 0.1
    @State private var logoOpacity: Double = 0
    @State private var textOffset: CGFloat = 50
    @State private var textOpacity: Double = 0
    
    private var shouldShowOnboarding: Bool {
        !UserDefaults.standard.hasRequestedPermissions
    }
    
    var body: some View {
        if isActive {
            ContentView()
        } else if showOnboarding {
            OnboardingPermissionView {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isActive = true
                }
            }
        } else {
            ZStack {
                // 動的背景
                AnimatedBackgroundView()
                
                // パーティクル効果
                ForEach(particles, id: \.id) { particle in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
                
                VStack(spacing: 40) {
                    // ロゴ部分
                    VStack(spacing: 20) {
                        ZStack {
                            // グロー効果
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.3),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .scaleEffect(showLogo ? 1.2 : 0.5)
                                .opacity(showLogo ? 0.6 : 0)
                            
                            // メインアイコン
                            Image(systemName: "motorcycle")
                                .font(.system(size: 70, weight: .light, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white, .blue.opacity(0.8)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .scaleEffect(logoScale)
                                .opacity(logoOpacity)
                                .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                        
                        // タイトルテキスト
                        VStack(spacing: 8) {
                            Text("BikeCollectionMemo")
                                .font(.custom("", size: 28))
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white, .blue.opacity(0.9)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(y: textOffset)
                                .opacity(textOpacity)
                            
                            Text("愛車と共に歩む記録")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .offset(y: textOffset)
                                .opacity(textOpacity)
                        }
                    }
                    
                    // ローディングアニメーション
                    LoadingAnimationView()
                        .opacity(textOpacity)
                }
            }
            .onAppear {
                startAnimations()
                generateParticles()
            }
        }
    }
    
    private func startAnimations() {
        // パーティクル更新
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            updateParticles()
            if isActive || showOnboarding {
                timer.invalidate()
            }
        }
        
        // ロゴアニメーション
        withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
            showLogo = true
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // テキストアニメーション
        withAnimation(.easeOut(duration: 0.8).delay(1.0)) {
            textOffset = 0
            textOpacity = 1.0
        }
        
        // 画面遷移
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                if shouldShowOnboarding {
                    showOnboarding = true
                } else {
                    isActive = true
                }
            }
        }
    }
    
    private func generateParticles() {
        let screenWidth: CGFloat = 400 // Default width
        let screenHeight: CGFloat = 800 // Default height
        
        particles = (0..<20).map { _ in
            Particle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                ),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.1...0.5),
                velocity: CGPoint(
                    x: CGFloat.random(in: -1...1),
                    y: CGFloat.random(in: -2...0)
                )
            )
        }
    }
    
    private func updateParticles() {
        let screenWidth: CGFloat = 400
        let screenHeight: CGFloat = 800
        
        for i in particles.indices {
            particles[i].position.x += particles[i].velocity.x
            particles[i].position.y += particles[i].velocity.y
            
            // 画面外に出たら反対側から出現
            if particles[i].position.y < 0 {
                particles[i].position.y = screenHeight
                particles[i].position.x = CGFloat.random(in: 0...screenWidth)
            }
            
            if particles[i].position.x < 0 || particles[i].position.x > screenWidth {
                particles[i].position.x = CGFloat.random(in: 0...screenWidth)
            }
        }
    }
}

struct AnimatedBackgroundView: View {
    @State private var gradientOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // ベース背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.15, green: 0.25, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 動くグラデーション
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color.clear,
                    Color.purple.opacity(0.2)
                ]),
                startPoint: UnitPoint(x: gradientOffset, y: 0),
                endPoint: UnitPoint(x: gradientOffset + 0.5, y: 1)
            )
            .onAppear {
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    gradientOffset = 1.0
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct LoadingAnimationView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .scaleEffect(0.5 + 0.5 * cos((rotation + Double(index) * 0.6) * .pi / 180))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct Particle {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    let opacity: Double
    let velocity: CGPoint
}

#Preview {
    SplashScreenView()
}