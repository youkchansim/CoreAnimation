# Layer Time
  * The biggest difference between time and space is that you can't reuse time. - Merrick Furst -

  * 앞의 두 장에서는 CAAnimation과 그 서브 클래스를 사용하여 구현할 수 있는 다양한 유형의 레이어 애니메이션에 대해 살펴보았다. 애니메이션은 시간이 지남에 따라 발생하는 변화이므로 타이밍은 전체 개념에 결정적이다. 이 장에서는 Core Animation이 시간을 추적하는 방법인 CAMediaTiming 프로토콜을 살펴볼 것이다.

## the CAMediaTiming Protocol
  * CAMediaTiming Protocol은 애니메이션 중에 시간 경과를 제어하는데 사용되는 속성 모음을 정의한다. CALayer와 CAAniamtion은 모두 이 프로토콜을 따르므로 개별 레이어 및 애니메이션 별로 시간을 제어할 수 있다.

### Duration and repetition
  * 8장 `Explicit Animations`에서 duration(CAMediaTiming 속성 중 하나)에 대해 갼락하게 언급하였다. duration 속성은 CFTimeInterval 유형이며 NSTimeInterval과 마찬가지로 초를 나타내는 `double-precision floating-point value`이다.
  * 애니메이션의 단일 반복이 실행되는 기간을 지정하는데 사용된다.
  * CAMediaTiming의 또 다른 속성은 repeatCount이다. 이 속성은 애니메이션이 반복 될 반복 횟수를 결정한다. repeatCount의 값은 애니메이션이 재생되는 총 횟수를 나타내며, duration이 2초이고 repeatCount가 3.5(애니메이션 3.5초)초로 설정되면 총 애니메이션 시간은 7초가 소요된다.
  * duration 및 repeatCount 속성은 모두 기본값이 0이다. 이 것은 애니메이션의 지속시간이 0초이거나 0번 반복된다는 의미가 아니다. 이 경우 단지 0의 값은 `기본값`을 의미하는데 이는 각각 0.25초 및 1번 반복을 의미한다.

![](Resource/9_1.png)
```Swift
class ViewController_9_1: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var durationField: UITextField!
    @IBOutlet weak var repeatField: UITextField!
    @IBOutlet weak var startButton: UIButton!
    
    @IBAction func startBtnAction(_ sender: Any) {
        let duration = Double(durationField.text ?? "") ?? 0
        let repeatCount = Float(repeatField.text ?? "") ?? 0
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = duration
        animation.repeatCount = repeatCount
        animation.byValue = M_PI * 2
        animation.delegate = self
        shipLayer.add(animation, forKey: "rotateAnimation")
        
        setControlsEnabled(enabled: false)
    }

    let shipLayer = CALayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shipLayer.frame = CGRect(x: 0, y: 0, width: 128, height: 128)
        shipLayer.position = CGPoint(x: 100, y: 100)
        shipLayer.contents = UIImage(named: "Ship")?.cgImage
        
        containerView.layer.addSublayer(shipLayer)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        hideKeyBoard()
    }
}

extension ViewController_9_1 {
    func setControlsEnabled(enabled: Bool) {
        for control: UIControl in [durationField, repeatField, startButton] {
            control.isEnabled = enabled
            control.alpha = enabled ? 1.0 : 0.25
        }
    }
    
    func hideKeyBoard() {
        durationField.resignFirstResponder()
        repeatField.resignFirstResponder()
    }
}

extension ViewController_9_1: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        setControlsEnabled(enabled: true)
    }
}
```

* 반복 애니메이션을 만드는 또 다른 방법은 repeatDuration 속성을 사용하는 것이다. 이 속성은 고정 된 반복 횟수 대신 특정 시간 동안 애니메이션이 반복되도록 하는것이다. 각 alternate cycle 동안 애니메이션이 뒤로 재생되도록 autoreverses라는 속성을 설정할 수 도 있다. 이것은 문이 열리고 나서 닫히는 것과 같이 연속적이지 않은 애니메이션을 계속 재생할 때 유용하다.
* 아래 예제는 autoreverses 속성을 사용하여 문을 자동으로 닫도록 한다. 이 경우 애니메이션이 무한대로 재생되도록 repeatDuration을 INFINITY로 설정하였다. repeatCount 및 repeatDuration 속성은 잠재적으로 서로 모순될 수 있으므로 둘중 하나만 사용하여야 한다. 두 속성이 0이 아닌 경우 해당 속성들은 정의되지 않는다.
![](Resource/9_2.png)
```Swift
class ViewController_9_2: UIViewController {
    @IBOutlet weak var containerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let doorLayer = CALayer()
        doorLayer.frame = CGRect(x: 0, y: 0, width: 128, height: 128)
        doorLayer.position = CGPoint(x: 100 - 64, y: 100)
        doorLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
        doorLayer.contents = UIImage(named: "Door")?.cgImage
        
        containerView.layer.addSublayer(doorLayer)
        
        let animation = CABasicAnimation(keyPath: "transform.rotation.y")
        animation.toValue = CGFloat(-M_PI_2)
        animation.duration = 2.0
        animation.repeatDuration = 100
        animation.autoreverses = true
        
        doorLayer.add(animation, forKey: nil)
    }
}
```

### Relative Time
* Core Animation에 관한 시간은 상대적이다. 각 애니메이션은 독립적으로 속도를 올리거나 지연시키거나 오프셋할 수 있는 자체 representation of time을 갖는다.
* beginTime 속성은 애니메이션이 시작되기 전의 시간 지연을 지정한다. 이 지연은 애니메이션이 표시되는 레이어에 추가 된 지점으로부터 측정되며 기본값은 0이다(즉, 바로 시작된다는 의미이다.).
* speed 속성은 시간 배율이다. 기본값은 1.0이지만 값을 감소시키면 레이어, 애니메이션의 시간이 느려지고 증가시키면 시간이 빨라질 것이다. 2.0의 속도에서는 명목상의 지속시간이 1초인 애니메이션이 실제로 0.5초 안에 완료된다. timeOffset 속성은 애니메이션의 시간을 이동한다는 점에서 beginTime과 비슷하다. 그러나 beginTime을 늘리면 애니메이션이 시작되기 전에 지연시간이 늘어나고 timeOffset을 늘리면 애니메이션의 특정 지점으로 빨리감기한다. 예를들어 1초동안 지속되는 애니메이션의 경우 0.5초의 timeOffset을 설정하면 애니메이션이 중간에서 시작된다.
* beginTime과 달리 timeOffset은 속도에 영향을 받지 않는다. 따라서 속도를 2.0으로 높이고 timeOffset을 0.5로 설정하면 1초 애니메이션이 2배 빠른속도로 0.5초동안 지속되므로 애니메이션 끝가지 효과적으로 건너뛴다. 그러나 timeOffset을 사용하여 애니메이션의 끝으로 건너 뛰더라도 총 재생시간 동안 재생된다.
# 아래는 speed 및 timeOffset 슬라이더를 원하는 값으로 설정한 다음 재생을 눌러 해당 효과를 보기위한 예제이다.
![](Resource/9_3.png)
```Swift
class ViewController_9_3: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var timeOffsetSlider: UISlider!
    @IBOutlet weak var timeOffsetLabel: UILabel!

    @IBAction func timeOffsetSliderAction(_ sender: Any) {
        updateTimeOffsetSlider()
    }
    
    @IBAction func speedSliderAction(_ sender: Any) {
        updateSpeedSlider()
    }
    
    @IBAction func playBtnAction(_ sender: Any) {
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.timeOffset = CFTimeInterval(timeOffsetSlider.value)
        animation.speed = speedSlider.value
        animation.duration = 1.0
        animation.path = bezierPath.cgPath
        animation.rotationMode = kCAAnimationRotateAuto
        animation.isRemovedOnCompletion = false
        shipLayer.add(animation, forKey: "slide")
    }
    
    let shipLayer = CALayer()
    let bezierPath = UIBezierPath()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bezierPath.move(to: CGPoint(x: 0, y: 100))
        bezierPath.addCurve(to: CGPoint(x: 300, y: 100), controlPoint1: CGPoint(x: 75, y: 100), controlPoint2: CGPoint(x: 225, y: 200))
        
        let pathLayer = CAShapeLayer()
        pathLayer.path = bezierPath.cgPath
        pathLayer.fillColor = UIColor.clear.cgColor
        pathLayer.strokeColor = UIColor.red.cgColor
        pathLayer.lineWidth = 3.0
        containerView.layer.addSublayer(pathLayer)
        
        shipLayer.frame = CGRect(x: 0, y: 0, width: 64, height: 64)
        shipLayer.position = CGPoint(x: 0, y: 100)
        shipLayer.contents = UIImage(named: "Ship")?.cgImage
        containerView.layer.addSublayer(shipLayer)
        
        updateSliders()
    }
}

extension ViewController_9_3 {
    func updateSliders() {
        updateSpeedSlider()
        updateTimeOffsetSlider()
    }
    
    func updateSpeedSlider() {
        let speed = speedSlider.value
        speedLabel.text = String(format: "%0.2f", speed)
    }
    
    func updateTimeOffsetSlider() {
        let timeOffset = timeOffsetSlider.value
        timeOffsetLabel.text = String(format: "%0.2f", timeOffset)
    }
}
```