# Timer-Based Animation
* I can guide you, but you must do exactly as I say.
* 10장 `easing`에서 CAMediaTimingFunction을 보았다. 이 기능을 사용하면 가속 및 감속과 같은 물리적 효과를 시뮬레이션하여 애니메이션의 easing을 더 현실적으로 제어할 수 있었다. 그러나 더욱 현실적인 물리적 상호작용을 시뮬레이션하거나 사용자 입력에 따라 즉석에서 애니메이션을 수정하려는 경우엔 어떻게 해야할까? 이 장에서는 타이머 기반 애니메이션을 탐색하여 애니메이션이 프레임 단위로 작동하는 방식을 정확하게 제어할 수 있도록 한다.

## Frame Timing
* 애니메이션은 연속적인 움직임을 나타내는 것처럼 보이지만 디스플레이 픽셀이 고정 된 위치에 있을 때 현실적으로 불가능하다. 보통 디스플레이는 연속적인 움직임을 표현할 수 없다. 디스플레이가 할 수 있는 일은 모션으로 인식할 수 있을 만큼 충분히 빠른 정적 이미지 시퀀스를 표시하는 것이다. 이전에 iOS가 초당 60회씩 화면을 새로 고친다고 언급하였다. CAAnimation은 일을 표시할 새 프레임을 계산한 다음 각 화면에 업데이트와 동기화하여 그린다. CAAnimation의 대단함은 매번 표시할 것을 산출하기 위해 interporation 및 easing 계산을 수행하는데 있다.
* 10장에서 우리는 보간법을 수행하고 스스로를 easing하는 법을 배운 다음 표시할 프레임 시퀀스를 제공하여 CAKeyframeAnimation 인스턴스에 정확히 무엇을 그릴지 지시하였다. 그 시점에서 모든 Core Animation은 우리가 명령한 프레임들을 순서대로 보여주었다.

### NSTimer
* 실제로 우리는 `Chatper3 - Geometry`에서 시계 예제를 하였는데, 이는 NSTimer를 사용하여 침들을 움직이는 애니메이션을 적용하였다. 이 예제에서 침은 초당 한번만 업데이트 되지만 타이머를 초당 60회 속도로 실행하면 prinsiple이 달라지지 않는다.
* CAKeyframeAnimation 대신 NSTimer를 사용하기 위해 10장에서 튀는 공 애니메이션을 수정해보자. 타이머가 시작될 때마다 애니메이션 프레임을 계속해서 계산할 것이기 때문에 애니메이션의 fromValue, toValue, duration 및 현재 timeOffset을 저장하기 위해 클래스에 몇 가지 추가 속성이 필요하다.

```Swift
class ViewController: UIViewController {
    @IBOutlet weak var ballView: UIImageView!
    
    var timer: Timer?
    var duration: TimeInterval = 0
    var timeOffset: TimeInterval = 0
    var fromValue: Any = NSValue(cgPoint: CGPoint.zero)
    var toValue: Any = NSValue(cgPoint: CGPoint.zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ballView.image = UIImage(named: "Ball")
        
        animate()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        animate()
    }
}

extension ViewController {
    func interpolate(from: CGFloat, to: CGFloat, time: CGFloat) -> CGFloat {
        return (to - from) * time + from
    }
    
    func interpolateFromValue(fromValue: Any, toValue: Any, time: CGFloat) -> Any {
        if let fromPoint = fromValue as? CGPoint, let toPoint = toValue as? CGPoint {
            let result = CGPoint(x: interpolate(from: fromPoint.x, to: toPoint.x, time: time), y: interpolate(from: fromPoint.y, to: toPoint.y, time: time))
            return NSValue(cgPoint: result)
        }
        
        return time < 0.5 ? fromValue : toValue
    }
    
    func quadraticEaseInOut(t: CGFloat) -> CGFloat {
        return t < 0.5 ? (2 * t * t) : (-2 * t * t) + (4 * t) - 1
    }
    
    func bounceEaseOut(t: CGFloat) -> CGFloat {
        if t < 4 / 11.0 {
            return (121 * t * t) / 16.0
        } else if (t < 8 / 11.0) {
            return (363 / 40.0 * t * t) - (99 / 10.0 * t) + 17 / 5.0
        } else if (t < 9/10.0) {
            return (4356 / 361.0 * t * t) - (35442 / 1805.0 * t) + 16061 / 1805.0
        }
        
        return (54 / 5.0 * t * t) - (513 / 25.0 * t) + 268 / 25.0;
    }
    
    func animate() {
        fromValue = NSValue(cgPoint: CGPoint(x: 120, y: 32))
        toValue = NSValue(cgPoint: CGPoint(x: 120, y: 268))
        duration = 3.0
        timeOffset = 0.0
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(timeInterval: 1/60.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
    }
    
    func step(timer: Timer) {
        timeOffset = min(timeOffset  + 1/60.0, duration)
        
        var time = timeOffset / duration
        time = TimeInterval(bounceEaseOut(t: CGFloat(time)))
        
        let position = interpolateFromValue(fromValue: fromValue, toValue: toValue, time: CGFloat(time))
        ballView.center = (position as? NSValue ?? NSValue(cgPoint: CGPoint.zero)).cgPointValue
        
        if timeOffset > duration {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}
```

* 잘 작동하고 키 프레임 기반 버전과 거의 동일한 코드 양이다. 그러나 우리가 한번에 많은 것을 애니메이션으로 만들려고 한다면 이 접근법에는 몇 가지 문제가 있다. Timer는 모든 프레임을 새로 고침해야 하는 화면에 물건을 그리므로 최적의 방법은 아니다. 그 이유를 이해하려면 Timer가 어떻게 작동하는지 정확히 알아야 한다. iOS의 모든 스레드는 NSRunloop을 유지 관리한다. NSRunloop은 간단히 말해서 수행해야 할 작업 목록을 통해 끝없이 작동하는 루프이다. 아래와 같은 작업이 mainThread에 포함될 것이다.
  * 터치 이벤트 처리
  * 네트워크 패킷 송수신
  * GCD를 사용하여 예약 된 코드 실행
  * 타이머 동작 처리
  * 화면 다시 그리기

* Timer를 설정하면 적어도 지정된 시간이 경과할 때 까지 실행해서는 안된다는 지시와 함께 이 작업 목록에 삽입된다. 타이머가 작동하기까지 대기하는 시간의 상한선은 없다. 목록의 이전 작업이 완료된 후에만 발생한다. 대개 예약 된 시간의 몇 밀리 초 내에 수행되지만 이전 작업이 완료되는 데 시간이 오래 걸릴 수 있다.
* 화면 다시 그리기는 60초마다 발생하도록 예약되지만 타이머 동작과 마찬가지로 목록의 이전 작업에 의해 지연되어 실행 시간이 오래 걸릴 수 있다. 이러한 지연은 무작위이기 때문에 화면이 다시 그려지기 전에 매 60초당 한번 씩 실행되도록 예약된 타이머가 항상 작동한다는 것을 보장할 수 없다. 때로는 화면 업데이트 사이에 두번 씩 실행될 수 있으므로 건너 뛴 프레임이 생겨 애니메이션이 앞으로 이동하는 것처럼 보일 수 있다. 우리는 이것을 개선하기 위해 몇 가지 일을 할 수 있다.
  * CADisplayLink라는 특수 유형의 타이머라는 것이 있는데 이는 화면 새로 고침을 정확하게 작동하도록 설계되어있다.
  * 프레임이 제 시간에 발사된다고 가정하지 않고 실제 기록 된 프레임 지속 시간에 애니메이션을 기반으로 할 수 있다.
  * 우리는 애니메이션 타이머의 실행 루프모드를 조정하여 다른 이벤트에 의해 지연되지 않도록 할 수 있다.

### CADisplayLink
* CADisplayLink는 CoreAnimation에서 제공하는 Timer와 같은 클래스로 화면이 다시 그려지기 직전에 항상 실행된다. 인터페이스는 Timer와 매우 유사하므로 본질적으로 drop-in 대체 기능이지만 초 단위로 지정된 timeInterval 대신 CADisplayLink에는 발생시킬 때 마다 건너 뛸 프레임 수를 지정하는 정수 frameInterval 속성이 있다. 기본적으로 이 값은 1이며 모든 프레임을 실행하게 된다. 그러나 애니메이션 코드가 60분의 1초 내에 안정적으로 실행되는 데 너무 오래 걸리는 경우 frameInterval을 2로 지정하면 애니메이션은 초당 30 프레임으로 애니메이트 될 것이다.(3으로 하면 초당 20프레임이 됨)
* Timer대신 CADisplayLink를 사용하면 프레임 속도를 가능한 한 일관성 있게 유지함으로써 보다 부드러운 애니메이션을 생성할 수 있다. 그러나 CADisplayLink조차도 모든 프레임이 일정대로 진행될 것이라고 보장할 수 없다. 흩어진 작업이나 리소스가 부족한 배경 응용 프로그램과 같이 사용자가 제어할 수 없는 이벤트로 인해 애니메이션이 때때로 프레임을 건너뛸 수 있다. Timer를 사용하면 기회가 생길 때마다 타이머가 작동하지만 CADisplayLink는 다르게 작동한다. 예약 된 프레임이 누락되면 프레임을 건너뛰고 다음 예약된 프레임 시간에 업데이트 된다.

## Measuring Frame Duration
* NSTimer 또는 CADisplayLink를 사용하는지 여부에 관계없이, 1초의 1/60의 예상 시간보다 프레임 계산 시간이 더 오래 걸리는 시나리오를 처리해야 한다. 실제 프레임 시간을 미리 알 수 없으므로 이를 측정해야한다. CACurrentMediaTime() 함수를 사용하여 각 프레임의 시작 부분에 시간을 기록한 다음 이전 프레임에 대해 기록된 시간과 비교함으로써 이를 수행할 수 있다.
* 이 시간을 비교함으로써 타이밍 계산을 위해 하드 코딩 된 1/60값 대신 정확한 프레임 duration 측정 시간을 얻을 수 있다. 이러한 개선 사항으로 다음 예를 보자.

```Swift
class ViewController: UIViewController {
    @IBOutlet weak var ballView: UIImageView!
    
    var timer: CADisplayLink?
    var duration: CFTimeInterval = 1.0
    var timeOffset: CFTimeInterval = 0.0
    var lastStep: CFTimeInterval = 0
    var fromValue: Any = NSValue(cgPoint: CGPoint(x: 150, y: 32))
    var toValue: Any = NSValue(cgPoint: CGPoint(x: 150, y: 268))

    override func viewDidLoad() {
        super.viewDidLoad()

        ballView.image = UIImage(named: "Ball")
        
        animate()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        animate()
    }
}

extension ViewController {
    func interpolate(from: CGFloat, to: CGFloat, time: CGFloat) -> CGFloat {
        return (to - from) * time + from
    }
    
    func interpolateFromValue(fromValue: Any, toValue: Any, time: CGFloat) -> Any {
        if let fromPoint = fromValue as? CGPoint, let toPoint = toValue as? CGPoint {
            let result = CGPoint(x: interpolate(from: fromPoint.x, to: toPoint.x, time: time), y: interpolate(from: fromPoint.y, to: toPoint.y, time: time))
            return NSValue(cgPoint: result)
        }
        
        return time < 0.5 ? fromValue : toValue
    }
    
    func bounceEaseOut(t: CGFloat) -> CGFloat {
        if t < 4 / 11.0 {
            return (121 * t * t) / 16.0
        } else if (t < 8 / 11.0) {
            return (363 / 40.0 * t * t) - (99 / 10.0 * t) + 17 / 5.0
        } else if (t < 9/10.0) {
            return (4356 / 361.0 * t * t) - (35442 / 1805.0 * t) + 16061 / 1805.0
        }
        
        return (54 / 5.0 * t * t) - (513 / 25.0 * t) + 268 / 25.0;
    }
    
    func animate() {
        ballView.center = CGPoint(x: 150, y: 32)
        
        duration = 1.0
        timeOffset = 0.0
        fromValue = NSValue(cgPoint: CGPoint(x: 150, y: 32))
        toValue = NSValue(cgPoint: CGPoint(x: 150, y: 268))
        
        timer?.invalidate()
        
        lastStep = CACurrentMediaTime()
        timer = CADisplayLink(target: self, selector: #selector(step))
        timer?.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
    }
    
    func step(timer: CADisplayLink) {
        let thisStep = CACurrentMediaTime()
        let stepDuration = thisStep - lastStep
        lastStep = thisStep
        
        timeOffset = min(timeOffset + stepDuration, duration)
        
        var time = timeOffset / duration
        time = CFTimeInterval(bounceEaseOut(t: CGFloat(time)))
        
        let position = interpolateFromValue(fromValue: fromValue, toValue: toValue, time: CGFloat(time))
        ballView.center = (position as? NSValue ?? NSValue(cgPoint: CGPoint.zero)).cgPointValue
        
        if timeOffset >= duration {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}
```

## Run Loop Modes
* CADisplayLink를 생성할 때 실행 루프를 지정하고 루프 모드를 실행해야 한다. 실행 루프의 경우 사용자 인터페이스 업데이트가 항상 주 스레드에서 수행되어야 하므로 Main 실행 루프(Main Thread에서 호스팅되는 실행 루프)를 사용하였다. 그러나 모드의 선택은 명확하지 않다. 실행 루프에 추가된 모든 태스크에는 우선 순위를 결정하는 모드가 있다. 사용자 인터페이스가 항상 원활하게 유지되도록 하기 위해 iOS는 사용자 인터페이스 관련 작업에 우선 순위를 부여하고 UI 활동이 너무 많으면 잠시 동안 다른 작업의 실행을 중지할 수 있다.
* 이에 대해 일반적인 예는 UIScrollView를 사용하여 스크롤하는 경우이다. 스크롤하는 동안 scrollView 내용을 다시 그리는 작업이 다른 작업보다 우선하므로 표준 NSTimer 및 네트워크 이벤트는 발생하지 않을 수 있다. 실행 루프 모드에 대한 일반적인 선택 사항은 다음과 같다.
  * NSDefaultRunLoopMode - 표준 우선 순위
  * NSRunLoopCommonModes - 높은 우선 순위
  * UITrackingRunLoopMode - UIScrollView 및 기타 컨트롤 애니메이션을 적용하는데 사용된다.

* 이 예제에서는 NSDefaultRunLoopMode를 사용했지만 애니메이션이 원활하게 실행되도록 NSRunLoopCommonModes를 대신 사용할 수 있다. 이 모드를 사용할 경우 애니메이션이 높은 프레임 속도로 실행될 때 주의해야한다. 왜냐하면 타이머와 같은 다른 작업 또는 스크롤과 같은 다른 iOS 애니메이션은 애니메이션이 끝날 때 까지 업데이트를 중지하기 때문이다.
* CADisplayLink는 동시에 여러개 사용이 가능마흐로 NSDefaultRunLoopMode 및 UITrackingRunLoopMode에 추가하여 다른 UIKit 컨트롤 애니메이션의 성능을 방해하지 않으면서 스크롤이 중단되지 않도록 할 수 있다.
```Swift
timer = CADisplayLink(target: self, selector: #selector(step))
timer?.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
timer?.add(to: RunLoop.main, forMode: .UITrackingRunLoopMode)
```
* CADisplayLink와 마찬가지로 NSTimer는 `scheduledTimerWithTimeInterval` 대신 대체 설정 코드를 사용하여 다른 실행 루프 모드를 사용하도록 구성할 수 있다.
```Swift
timer = Timer.scheduledTimer(timeInterval: 1/60.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
RunLoop.main.add(timer, forMode: .commonModes)
```

## Physical Simulation
* 10장에서 키프레임 애니메이션의 동작을 복제하기 위해 타이머 기반 애니메이션을 사용해왔지만 사실 실제로 작동하는 방식에는 근본적인 차이가 있다. 키 프레임 구현시 사전에 모든 프레임을 계산해야 했지만, 새로운 솔루션에서는 요구에 따라 계산한다. 이것은 사용자 입력에 따라 애니메이션 로직을 즉석에서 수정하거나 물리 엔진과 같은 다른 실시간 애니메이션 시스템과 통합할 수 있다는 것을 의미힌다.

### Chipmunk
* 현재의 Easing 기반 바운스 애니메이션 대신 물리학을 사용하여 사실적인 중력 시뮬레이션을 만든다. 2D에서 조차 정확하게 물리 시뮬레이션은 매우 복잡하기 때문에 이것을 처음부터 구현하려고 하지 않을 것이다. 대신 오픈소스 물리 라이브러리 또는 엔진을 사용할 수 있다.
* 우리가 사용할 물리엔진은 `Chipmunk`이다. 다른 2D 물리 라이브러리(예: Box2D)를 사용할 수 있지만 `Chipmunk`는 C++대신 순수 C로 작성돼있으므로 Objective-C 프로젝트에 쉽게 통합할 수 있다. Chipmunk는 다양한 종류가 있으며, Objective-C 바인딩을 사용하는 `Indie`버전을 포함한다. 일반 C버전은 무료이지만 이 예제에서는 이 버전을 사용할 것이다. 버전 6.1.4는 서면 작성 당시 최신 버전이다. [여기](http://chipmunk-physics.net)에서 다운로드 할 수 있다.
* Chipmunk 물리 엔진은 전체적으로 매우 크고 복잡하지만 다음 클래스만 사용한다.
  * cpSpace - 모든 물리학 체제의 컨테이너이다. 이것은 크기와(선택적으로) 중력 벡터를 가지고 있다.
  * cpBody - 단단하고 비탄력적인 객체이다.이것은 공간에서의 위치와 질량, 순간, 마찰계수 등과 같은 다른 물리적 특성을 가지고 있다.
  * cpShape - 충돌을 감지하는데 사용되는 추상적인 기하학적 모양이다. 여러 모양이 본문에 첨부될 수 있으며 cpShape의 구체적인 하위 클래스가 서로 다른 모양 유형을 나타낸다.

* 이 예제에서는 중력의 영향을 받는 나무상자를 모델링한다. 화면 상에있는 나무상자의 시각적 표현(UIImageView)과 이것을 표현하는 물리적 모델(사각형 상자를 나타내는데 사용할 다각형 cpShape 하위 클래스인 cpBody 및 cpPolyShape)을 모두 포함하는 Crate 클래스를 생성한다.
* Chipmunk의 C 버전을 사용하면 Objective-C의 참조 계산 모델을 지원하지 않기 때문에 몇 가지 문제가 발생하므로 명시적으로 객체를 생성하고 해제해야한다. 이를 단순화하기 위해 cpay와 cpBody의 수명을 crate 클래스의 `init` 메소드에서 생성하고 dealloc에서 해제하여 Crate 클래스에 연결한다. 나무 상자의 물리적 속성의 구성은 상당히 복잡하지만 Chipmunk 설명서를 읽는다면 의미가 있다.
* 뷰 컨트롤러는 이전처럼 타이머 로직과 함께 cpSpace를 관리한다. 각 단계에서 우리는 cpSpace(물리 계산을 수행하고 전 세계의 모든 몸체를 재배치)를 업데이트 한 다음 bodies를 반복하고 해당 bodies을 모델링 한 bodies와 일치하도록 Crate views의 위치를 업데이트한다.(이 경우 실제로는 하나의 바디만 있지만 나중에 더 추가될 것이다.)
* Chipmunk는 UIKit에 대해 역 좌표계를 사용한다.(Y 축은 위를 향함) 물리 모델을 뷰와 동기화하여 유지하기 쉽게하기 위해 geomeryFlipped 속성(3장 참조)을 사용하여 컨테이너 뷰의 지오메트리를 반전하므로 모델과 뷰가 모두 동일한 좌표계를 사용한다.
* Crate 예제 코드는 아래와 같다. 어디에서나 cpSpace 객체를 해제하지는 않는다. 어쨋든 이 간단한 예제에서는 앱 수명기간 동안 공간이 존재하므로 실제 문제는 아니지만 실제 시나리오에서는 Crate 본체와 동일한 방식으로 이를 처리해야 한다. 독립형 Cocoa 객체로 래핑하고 Chipmunk 객체의 수명 주기를 관리하는데 사용한다.

![](Resource/11_1.png)
```Swift
class Crate: UIImageView {
    let MASS: cpFloat = 100
    
    var body: UnsafeMutablePointer<cpBody>
    var shape: UnsafeMutablePointer<cpShape>
    
    override init(frame: CGRect) {
        body = cpBodyNew(MASS, cpMomentForBox(MASS, cpFloat(frame.size.width), cpFloat(frame.size.height)))
        
        let corners = [
            cpv(0, 0),
            cpv(0, cpFloat(frame.size.height)),
            cpv(cpFloat(frame.size.width), cpFloat(frame.size.height)),
            cpv(cpFloat(frame.size.width), 0),
        ]
        
        shape = cpPolyShapeNew(body, Int32(corners.count), UnsafeMutablePointer(mutating: corners), cpv(cpFloat(-frame.size.width) / 2, cpFloat(-frame.size.height) / 2))
        
        super.init(frame: frame)
        
        image = #imageLiteral(resourceName: "Crate")
        contentMode = UIViewContentMode.scaleAspectFill
        
        cpShapeSetFriction(shape, 0.5)
        cpShapeSetElasticity(shape, 0.8)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ViewController_11_3: UIViewController {
    @IBOutlet weak var containerView: UIView!
    
    let GRAVITY = 1000
    
    var space: UnsafeMutablePointer<cpSpace>?
    var timer: CADisplayLink?
    var lastStep: CFTimeInterval = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.isGeometryFlipped = true
        
        space = cpSpaceNew()
        cpSpaceSetGravity(space, cpv(0, -(Float(GRAVITY))))
        
        let crate = Crate(frame: CGRect(x: 100, y: 0, width: 100, height: 100))
        containerView.addSubview(crate)
        
        cpSpaceAddBody(space, crate.body)
        cpSpaceAddShape(space, crate.shape)
        
        lastStep = CACurrentMediaTime()
        timer = CADisplayLink(target: self, selector: #selector(step))
        timer?.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
    }
}

extension ViewController_11_3 {
    func updateShape(shape: UnsafeMutablePointer<cpShape>?, unused: UnsafeMutableRawPointer?) -> Void {
        let crate = shape?.pointee.data.assumingMemoryBound(to: Crate.self).pointee
        let body = shape?.pointee.body
        crate?.center = cpBodyGetPos(body)
        crate?.transform = CGAffineTransform(rotationAngle: CGFloat(cpBodyGetAngle(body)))
    }
    
    func step(timer: CADisplayLink) {
        let thisStep = CACurrentMediaTime()
        let stepDuration = thisStep - lastStep
        lastStep = thisStep
        
        cpSpaceStep(space, cpFloat(stepDuration))
        
        let b: cpSpaceShapeIteratorFunc = { shape, data in
            let crate = shape?.pointee.data.assumingMemoryBound(to: Crate.self).pointee
            let body = shape?.pointee.body
            crate?.center = cpBodyGetPos(body)
            crate?.transform = CGAffineTransform(rotationAngle: CGFloat(cpBodyGetAngle(body)))
        }
        
        cpSpaceEachShape(space, b, nil)
    }
}
```