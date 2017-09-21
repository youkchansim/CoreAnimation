# Efficient Drawing
* More computing sins are committed in the name of efficiency (without necessarily achieving it) than for any other single reason—including blind stupidity. - William Allan Wulf
* 12장 `Tuning for Speed`에서 Instruments를 사용하여 Core Animation 성능문제를 진단하는 방법을 살펴보았다. iOS 앱을 제작할 때 많은 잠재적인 성능 함정이 있지만 이 장에서는 드로잉 성능과 관련된 문제에 중점을 둔다.

## Software Drawing
* 드로잉이라는 용어는 일반적으로 Core Animation의 맥락에서 소프트웨어 드로잉(즉, GPU 지원이 아닌 드로잉)을 의미한다. iOS의 소프트웨어 드로잉은 주로 COre Graphics 프레임 워크를 사용하여 수행되며 때로는 필요하지만 Core Animation 및 OpenGL에서 하드웨어 가속 렌더링 및 합과 비교할 때 속도가 느리다.
* 소프트웨어 드로잉은 속도가 느린 것 외에도 많은 메모리가 필요하다. CALayer는 그 자체로 메모리가 비교적 적다. RAM의 중요한 공간을 차지하는 것은 Backing Image 일뿐이다. contents 속성에 직접 이미지를 할당하더라도 이미지의 단일(압축되지 않은) 복사본을 저장하는데 필요한 메모리를 초과하는 추가 메모리는 사용하지 않는다. 동일한 이미지가 여러 레이어의 내용으로 사용되면 해당 메모리는 복제되지 않고 공유된다.
* 그러나 `CALayerDelegate -drawLayer: inContext` 메소드 또는 `UIView -drawRect` 메소드 (후자는 이전 래퍼를 감싸는 래퍼)를 구현하자마자 오프 스크린 드로잉 컨텍스트가 레이어에 대해 만들어지며 해당 컨텍스트는 레이어의 너비 x 높이(픽셀이 아니라 포인트) x 4바이트의 메모리를 요구한다. Retina iPad의 전체화면 레이어의 경우 2048*1536*4 바이트로 RAM에 저장해야하는 전체 12MB이지만 레이어를 다시 그릴 때마다 다시 채워야 한다. 소프트웨어 도면은 비용이 많이 들기 때문에 절대적으로 필요한 경우가 아니면 view를 다시 그리지 않는게좋다. 드로잉 성능 향상의 비결은 일반적으로 가능한 한 적은 드로잉을 시도하는 것이다.

## Vector Graphics
* Core Graphics 드로잉을 사용하는 일반적인 이유는 이미지나 레이어 효과를 사용하여 쉽게 생성할 수 없는 벡터 그래픽에 대한 것이다. 벡터 드로잉에는 다음이 포함될 수 있다.
  * 임의의 다각형
  * 대각선 또는 곡선
  * 컨텍스트
  * 그라디언트

* 예를들어 보자. 아래 예제는 기본적인 라인 드로잉 애플리케이션을 위한 코드이다. 이 응용 프로그램은 UIBezierPath의 점으로 사용자 Touch를 변환한 다음 뷰에 그린다. 이 경우 DrawingView라는 UIView 하위 클래스에 모든 드로잉 로직이 포함되어 있지만(뷰컨트롤러는 비어있음) 원하는 경우 뷰컨트롤러에서 터치 핸들링을 구현할 수 있다.
![](Resource/13_1.png)

```Swift
class DrawingView: UIView {
    let path = UIBezierPath()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        
        path.lineWidth = 5
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first?.location(in: self) {
            path.move(to: point)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first?.location(in: self) {
            path.addLine(to: point)
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        UIColor.clear.setFill()
        UIColor.red.setStroke()
        path.stroke()
    }
}
```
* 위 구현의 문제점은 드로잉이 많을수록 느리게 진행된다는 것이다. 우리가 손가락을 움직일 때마다 전체 UIBezierPath를 다시 그리기 때문에 경로가 복잡해지면서 프레임 속도가 떨어져 수행해야하는 그리기 작업이 매 프레임마다 증가한다. 더 나은 접근 방식이 필요하다.
* Core Animation은 하드웨어 지원을 통해 이러한 유형의 도형을 그리는데 필요한 스페셜리스트 클래스를 제공한다(6장에서 자세히 설명함).
* CAShapeLayer를 사용하여 다각형, 선 및 곡선을 그릴 수 있다. 그라디언트는 CAGradientLayer를 사용하여 그릴 수 있다. 이것들은 모두 Core Graphics를 사용하는 것보다 훨씬 빠르며 이미지를 생성하는 오버헤드를 피할 수 있다.
* Core Graphics 대신 CAShapeLayer를 사용하도록 드로잉 앱을 수정하면 성능이 크게 향상된다. 성능은 필연적으로 경로의 복잡성이 증가함에 따라 저하되지만 프레임 속도와 상당한 차이를 만들기 위해서는 매우 복잡한 도면이 필요하다.
```Swift
class DrawingView: UIView {
    let path = UIBezierPath()
    
    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let layer = self.layer as? CAShapeLayer {
            let shapeLayer: CAShapeLayer = layer
            shapeLayer.strokeColor = UIColor.red.cgColor
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.lineJoin = kCALineJoinRound
            shapeLayer.lineCap = kCALineCapRound
            shapeLayer.lineWidth = 5
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first?.location(in: self) {
            path.move(to: point)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first?.location(in: self) {
            path.addLine(to: point)
            if let layer = self.layer as? CAShapeLayer {
                layer.path = self.path.cgPath
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        UIColor.clear.setFill()
        UIColor.red.setStroke()
        path.stroke()
    }
}
```
