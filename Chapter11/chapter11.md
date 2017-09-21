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
* Timer대신 CADisplayLink를 사용하면 프레임 속도를 가능한 한 일관성 있게 유지함으로써 보다 부드러운 애니메이션을 생성할 수 있다. 그러나 CADisplayLink조차도 모든 프레임이 일정대로 진행될 것이라고 보장할 수 없다. 흩어진 작업이나 리소스가 부족한 배경 응용 프로그램과 같이 사용자가 제어할 수 없는 이벤트로 인해 애니메이션애 때때로 프레임을 건너뛸 수 있다. Timer를 사용하면 기회가 생길 때마다 타이머가 작동하지만 CADisplayLink는 다르게 작동한다. 예약 된 프레임이 누락되면 프레임을 건너뛰고 다음 예약된 프레임 시간에 업데이트 된다.