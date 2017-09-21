# Easing
* In life, as in art, the beautiful moves in curves. - Edward G. Bulwer-Lytton -
* 9장 `Layer Time`에서는 애니메이션 타이밍과 CAMediaTiming 프로토콜에 대하여 설명하였다. 이제 우리는 또 다른 시간 관련 매커니즘인 `Easing`라고 알려진 시스템에 대하여 살펴볼 것이다. Core Animation은 `Easing`을 사용하여 로봇 및 인공물처럼 보이는것 대신 자연스럽고 부드럽게 움직이는 애니메이션을 만든다. 이 장에서는 애니메이션의 `Easing curves`를 제어하고 사용자 정의하는 방법에 대하여 살펴볼 것이다.

## Animation Velocity
* 애니메이션은 시간이 지남에 따라 값이 변하는 것을 의미하며 이는 특정 비율 또는 속도로 변하는것을 함축한다. 애니메이션의 속도는 지속시간과 관련하여 다음 방정식을 이용하여 구할 수 있다.
```
Velocity = change / time
```
* `change`는 물체가 움직이는 거리(예를들어)이며, `time`은 애니메이션의 지속시간이다. 이동(position 또는 bounds 속성의 애니메이션과 같은)이 포함된 애니메이션의 경우 시각화가 더 쉽지만 애니메이티브 속성(예: 색상 또는 불투명도)에도 똑같이 적용된다.
* 위의 수식은 속도가 애니메이션 전체에서 일정하다고 가정한 것이다(8장 `Implicit Animations`에서 생성한 애니메이션의 경우). 애니메이션에 일정한 속도를 사용하는 것을 `Linear pacing`라고하며 기술적인 관점에서 보면 애니메이션을 구현하는 가장 간단한 방법이다. 또한 완전히 비현실적이다.
* 짧은 거리를 운전하는 자동차를 생각해보면 60mph에서 시작하지 않을것이고 목적지에 도착 시 즉시 0mph로 떨어질 것이다. 한 가지는 무한대로 가속해야 한다는 것이다.
* 현싲럭으로 천천히 전속력으로 가속화 될 것이고 목적지가 가까워지면 마침내 완만하게 멈출때까지 속도가 느려질 것이다.
* 다른 예로 표면에 떨어지는 물체는 정지상태로 시작한 다음 표면에 닿을때 까지 계속 가속한다. 현실세계의 모든 물체는 가속하고 감속한다. 그렇다면 애니메이션에서 이러한 종류의 가속을 어떻게 구현할까? 하나의 옵션은 물리 엔진을 사용하여 애니메이션 오브젝트의 마찰과 운동량을 현실적으로 모델링하는 것이지만 대부분의 경우 과잉이다. 애니메이션 사용자 인터페이스의 경우 우리는 레이어를 실제의 실물처럼 움직일 수 있는 몇가지 타이밍 방적식을 원하지만 계산하는것은 너무 복잡하다. 이러한 유형의 방정식에 대한 이름은 기능을 완화하는 것이며, 다행스럽게도 Core Animation에는 여러가지 기본 기능이 내장되어있어 사용할 준비가 되어있다.

### CAMediaTimingFunction
* Easing 함수를 사용하려면 CAMediaTimingFunction 클래스의 객체인 CAAnimation의 timingFunction 속성을 설정해야 한다. Implicit Animation의 타이밍 함수를 변경하려면 CATransaction의 `setAnimationTimingFunction` 메서드를 사용할 수도 있다. CAMediaTimingFunction을 만드는 데는 두 가지 방법이 있다. 가장 간단한 옵션은 `timingFunctionWithName` 생성자 메서드를 호출하는 것이다. 이것은 아래 상수 중 하나를 가져올 수 있다.
  * kCAMediaTimingFunctionLinear
  * kCAMediaTimingFunctionEaseIn
  * kCAMediaTimingFunctionEaseOut
  * kCAMediaTimingFunctionEaseInEaseOut
  * kCAMediaTimingFunctionDefault
* `kCAMediaTimingFunctionLinear`옵션은 linear paced timing function함수를 생성한다. linear pacing은 거의 순간족으로 가속되는 것을 모델링 한 다음 목표에 도착할 때까지 크게 느려지지 않는다.
* `kCAMediaTimingFunctionEaseIn` 상수는 느리게 시작하여 갑자기 멈추기 전에 최대 속도까지 점진적으로 가속하는 함수를 만든다. 이것은 앞에서 언급한 추락 된 무게 예제 또는 목표물에서 발사된 미사일과 같은 것에 적합하다.
* `kCAMediaTimingFunctionEaseOut` 상수는 그 반대이다. 이것은 최고속도로 시작하고 점차 속도가 느려진다. 이것은 일종의 감쇠효과가 있으며 문이 열리고 닫히는 애니메이션에 적합하다.
* `kCAMediaTimingFunctionEaseInEaseOut` 상수는 최고 속도까지 점진적 가속도를 생성한 다음 부드럽게 감속하여 정지한다. 이것은 일반적으로 대부분의 실제 객체가 움직이는 방식이며 대부분의 애니메이션에서 최상의 선택이다. 하나의 Easing 함수만 선택할 수 있다면 이 함수가 된다. 이 사실을 감안할 때 왜 이것이 기본값이 아닌지 궁금해 할 수 없다. 사실 UIView 애니메이션 메서드를 사용할 때 이것이 기본값이지만 CAAnimation을 만들 때는 직접 지정해야한다.
* `kCAMediaTimingFunctionDefault` 상수는 `kCAMediaTimingFunctionEaseInEaseOut`과 매우 유상한 특징을 가졌지만 최고 속도까지 약간 더 빠른 초기 가속도와 약간 더 점진적인 감속이 뒤따르는 가속도를 만든다. `kCAMediaTimingFunctionEaseInEaseOut`과 차이는 거의 눈에 띄지 않지만 Apple은 암시적 애니메이션의 기본값으로 더 나은 선택이라고 생각했다(대신 `kCAMediaTimingFunctionEaseInEaseOut`를 기본값으로 사용하는 UIKit에 대한 마음이 바뀌었다.). 이름에도 불구하고 명시적 CAAnimation을 만들 때 이 값이 기본값이 아니며 암시적 애니메이션의 기본 값으로만 사용된다(즉, 기본 레이어 액션 애니메이션은 `kCAMediaTimingFunctionDefault`를 타이밍 기능으로 사용한다.).
* 간단한 테스트 프로젝트를 만들어 다양한 Easing 함수를 시험해 볼 것이다.
```Swift
class ViewController: UIViewController {
    let colorLayer = CALayer()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        colorLayer.position = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.width / 2)
        colorLayer.backgroundColor = UIColor.red.cgColor
        view.layer.addSublayer(colorLayer)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(1.0)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
        
        colorLayer.position = touches.first?.location(in: view) ?? colorLayer.position
        
        CATransaction.commit()
    }
}
```