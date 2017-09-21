# Implicit Animations

### Transactions
- Core Animation은 화면 상에 있는 모든 것들이 움직일 것이라는 가정하에 만들어졌다. CALayer의 애니메이션 가능한 속성을 변경할 때 마다
변경 사항이 화면에 즉시 반영되는 것이 아니라 이전 값에서 부터 새 값으로 부드럽게 움직인다.

- 특정 레이어의 컬러 속성값을 변경하는 것(어떤 종류의 애니메이션을 원하는지 명시하지 않음)을 Implicit Animation(암시적 애니메이션)이라고 한다.
```Swift
class ViewController: UIViewController {
    @IBOutlet weak var layerView: UIView!

    @IBAction func buttonAction(_ sender: Any) {
        changeColor()
    }

    var layer = CALayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layer.frame = CGRect(x: 50, y: 50, width: 100, height: 100)
        layer.backgroundColor = UIColor.blue.cgColor
        
        layerView.layer.addSublayer(layer)
    }
    
    func changeColor() {
        let red = CGFloat(arc4random()) / CGFloat(INT_MAX)
        let green = CGFloat(arc4random()) / CGFloat(INT_MAX)
        let blue = CGFloat(arc4random()) / CGFloat(INT_MAX)
        
        layer.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0).cgColor
    }
}
```
- Transactions 이란 Core Animation이 특정 속성 애니메이션 집합을 캡슐화하는데 사용하는 메커니즘이다. 해당 트랜잭션 내에서 변경되는 모든 애니메이션 가능 레이어 속성은
즉시 변경되지 않지만 해당 트랜잭션이 커밋되는 순간 새 값으로 애니메이션을 시작한다. 즉 몇몇 애니메이션들을 그룹화 할 수 있다.

- Transactions는 CATransaction 클래스를 사용하여 관리된다. 단일 트랜잭션을 나타내지 않으며 직접 액세스 하지 않고 트랜잭션 스택을
관리한다는 독특한 디자인을 갖고 있다. 프로퍼티나 메소드가 없으며, alloc, init을 사용하여 트랜잭션을 만들 수 없다. 하지만 begin, commit를 사용하여
새 트랜잭션을 스택에 푸시하거나 현재 트랜잭션을 팝할 수 있다.

- CATransaction에서 사용할 수 있는 기능
  - begin
  - commit
  - setAnimationDuration : 현재 트랜잭션의 애니메이션 지속 시간 설정
  - animationDuration : 현재 트랜잭션의 애니메이션 지속 시간 확인

- Core Animation은 실행 루프의 반복마다 자동으로 새 트랜잭션을 시작한다.
- UIView에도 beginAnimations, commitAnimations가 있다. 이는 UIView가 내부적으로 CATransaction을 사용하고 있음을 의미한다. iOS 4부터 UIView에서 블록 기반의 애니메이션을 설정할 수 있는데
이는 결국 내부적으로 CATransaction을 사용한다.

### Completion Blocks
- UIView의 애니메이션에서 Completion 블럭을 제공하는데 이는 CATransaction의 setCompletionBlock 메소드를 호출하여 구현한 것이다.
- 위의 코드에서 setAnimationDuration 아래에 다음과 같은 코드를 추가한다.
```Swift
CATransaction.setCompletionBlock {
            var transform = self.layer.affineTransform()
            transform = transform.rotated(by: CGFloat(M_PI_2))
            self.layer.setAffineTransform(transform)
        }
```
- 위의 코드는 색상 애니메이션보다 훨씬 빠르다. 회전 애니메이션을 적용하는 완료 블록은 색상 변경 애니메이션의 트랜잭션이 커밋되고 스택에서 튀어나온 후에 실행되기 때문이다.
그러므로 기본 0.25 초로 트랜잭션을 사용한다.

### Layer Actions
- CALayer가 자동으로 적용하는 애니메이션을 Action이라고 한다.
  1. 계층에 Delegate가 있는지 여부와 Delegate가 CALayerDelegate 프롵토콜에 지정된 actionForLayer 메서드를 구현하는지 여부를 확인한다. 그럴 경우 호출하고 결과를 반환합니다.
  2. Delegate가 없거나 Delegate가 actionForLayer 메서드를 구현하지 않으면 레이어는 Action Dictionary를 확인한다. 여기에는 Action에 대한 속성 이름이 매핑되어 있다.
  3. Action Dictionary에 question의 속성에 대한 항목이 포함되어 있지 않으면 레이어는 Style Dictionary hierarchy에서 속성 이름과 일치하는 모든 작업을 검색한다.
  4. 마지막으로 Style Dictionary hierarchy의 아무 곳에서나 적절한 동작을 찾지 못하면 레이어는 알려진 속성의 표준 동작을 정의하는 defaultActionForKey 메서드를 호출하도록 fall back한다.

```Swift
class ViewController: UIViewController {
    @IBOutlet weak var layerView: UIView!

    @IBAction func buttonAction(_ sender: Any) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(1.0)
        CATransaction.setCompletionBlock {
            var transform = self.layer.affineTransform()
            transform = transform.rotated(by: CGFloat(M_PI_2))
            self.layer.setAffineTransform(transform)
        }
        
        if flag == 0 {
            flag = 1
            changeColor()
        } else {
            flag = 0
            changeColorToWhite()
        }
        
        CATransaction.commit()
    }

    var layer = CALayer()
    var flag = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layerView.layer.backgroundColor = UIColor.blue.cgColor
    }
    
    func changeColor() {
        let red = CGFloat(arc4random()) / CGFloat(INT_MAX)
        let green = CGFloat(arc4random()) / CGFloat(INT_MAX)
        let blue = CGFloat(arc4random()) / CGFloat(INT_MAX)
        
        layerView.layer.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0).cgColor
    }
    
    func changeColorToWhite() {
        layer.backgroundColor = UIColor.white.cgColor
    }
}
```
- 위의 코드는 애니메이션이 적용되지 않는 코드이다. 그 이유는 actionForKey에서 nil을 반환하기 때문이다. UIKit는 암시적 애니메이션을 비활성화하며, 모든 UIView는 백업 레이어의 Delegate 역할을 하여 actionForLayer 메서드에 대한 구현을 제공한다.
그러므로 애니메이션 블록 내부에 있지 않으면 UIView는 모든 레이어 액션에 대해 nil을 반환하지만 애니메이션 블록의 범위 내에서 nil이 아닌 값을 반환한다.
- 아래와 같은 간단한 에제를 통해 쉽게 위의 정의를 확인할 수 있다.
```Swift
    override func viewDidLoad() {
        super.viewDidLoad()   
        print(layerView.action(for: layerView.layer, forKey: "backgroundColor") ?? "nil")
        
        UIView.beginAnimations(nil, context: nil)
        print(layerView.action(for: layerView.layer, forKey: "backgroundColor") ?? "nil")
        UIView.commitAnimations()
    }
```
- 암시적인 애니메이션을 비활성화하는 유일한 방법은 액션에 대한 nil을 반환하는 것이 아니라 setDisableActions라는 메서드를 통해 암시적 애니메이션을 동시에 활성화하거나 비활성화 할 수 있다.
- 위를 요악하면 아래와 같은것을 배웠다.
  1. UIView 지원 레이어에는 암시적 애니메이션이 활성화되어 있지 않으며, Backing 레이어의 속성을 애니메이션으로 만드는 유일한 방법은
  CATransaction에 의존하는 대신 UIView 애니메이션 메서드를 사용하는 것이다. 그리고 UIVIew 자체를 하위 클래스로 만들고 actionForLayer 메서드를 재정의 하거나 명시적 애니메이션(8장)을 마드는 것이다.
  2. 호스팅 된 레이어의 경우 actionForLayer Delegate 메서드를 구현하거나 Action Dictionary를 제공하여 암시적 속성 애니메이션에 대해 선택된 애니메이션을 제어할 수 있다.
  Action은 대게 코어 애니메이션이 필요할 때 암묵적으로 호출되는 명시적 애니메이션 객체를 사용하여 지정된다. 여기에서 사용하고 있는 애니메이션은 CATransition의 인스턴스로 구현된다.

### Presentation Versus Model
  - CALayer의 속성을 변경하면 즉작적인 영향은 없지만 시간이 지남에 따라 점진적으로 업데이트 된다. 이는 레이어의 속셩을 변경하면 속서값은 실제로 즉시 업데이트 되지만 해당 속성이 레이어의 모양을 직접 관여하지 않기 때문이다. 대신 속성의 애니메이션이 완료될 때 레이어가 가질 모양을 정의한다.
  - CALayer의 속성을 설정할 때 디스플레이가 현재 트랜잭션의 끝을 바라 보는 방식에 대한 모델을 실제로 정의하고 있다. Core Animation은 컨트롤러 역할을 하며 레이어 액션 및 트랜잭션 설정에 따라 화면에서 이러한 속성의 뷰 상태를 업데이트 할 책임이 있습니다.
  - 사실상 미니어처의 MVC  패턴이다. 사실 Apple의 문서에서 레이어 트리는 모델 레이어 트리라고도 불린다.
  - iOS에서는 화면이 초당 60회 다시 그려진다.
  - 각 레이어 속성의 표시값은 presentationLayer 메서드를 통해 액세스 되는 프레젠테이션 레이어라는 별개의 레이어에 저장된다. 프레젠테이션 레이어는 본질적으로 모델 레이어(레이어 트리)의 복제본이다.
  단, 속성 값은 항상 특정 시점의 현재 모양을 나타낸다.
  - 프레젠 테이션 레이어는 레이어가 처음으로 커밋될 때(즉, 스크린에 처음 표시될 때)에만 생성되므로, 그 전에 presentationLayer를 호출하면 nil이 반환된다.(viewDidAppear 메소가 아닌 다른 메소드에서 애니메이션이 먹지 않는 이유가 여기에 있다.)
  - 프레젠테이션 레어어가 유용한 두 가지 경우는 애니메이션을 동기화하고 사용자 상호 작용을 처리하는 것이다.
    - 타이머 기반 애니메이션을 구현하는 경우 특정 레이어가 화면 상에 나타나는 위치를 정확히 알 수있는 것이 유용할 수 있다.
    - 이전 장에서 배운 hitTest 메소드의 경우 사용자가 보고있는 레이어의 위치를 나타내므로 모델레이어가 아닌 프레젠테이션 레이어와 비교하여 반환한다.
    - hitTest로 레이어를 움직이는 것을 구현했을 때 레이어 자체에서 hitTest를 하면 움직임이 잘 안된다. 그 이유는 움직임을 위해 터치한 포인트가 즉각적으로 해당 레이어에 반영되기 때문이다. 하지만 프레젠테이션 레이어는 레이어가 커밋된 후 반영되기 때문에 프레젠테이션 레이어에서 hitTest를 하면 정상적으로 작동하는 것을 볼 수 있다. 이 점이 가장 중요한 점이다.
