# Layer Geometry

### Layout

UIView는 3개의 주요한 레이아웃 속성들을 갖는다.(frame, bounds, center). 이것과 동등하게 CALayer에서는 frame, bounds, position을 갖는다.
뷰의 frame, bounds 및 center 속성은 실제로는 해당 레이어의 해당 레이어에 대한 접근 자 (setter 및 getter 메서드)입니다. 뷰 프레임을 조작하면 실제 CALayer의 프레임이 변경된다.
frame property는 virtual property이다.
frame은 bounds와 position, transform의 변경에 의해 계산되는 가상의 프로퍼티임. 거꾸로 말하면 frame을 변경하면 bounds와 position이 변경될 수 있음을 뜻함.

### anchorPoint

앞서 언급했듯이 뷰의 center 속성과 레이어의 position 속성은 레이어의 anchorPoint 위치를 슈퍼 레이어와 관련하여 지정한다.
즉 anchorPoint는 레이어를 이동하는 데 사용되는 핸들이라고 할 수 있다.
기본적으로 anchorPoint는 레이어의 가운데에 위치하므로 레이어가있는 위치에 상관없이 레이어가 해당 위치를 중심으로 배치된다.
anchorPoint는 UIView 인터페이스에서 노출되지 않으므로 뷰의 position 속성은 "center"라고 불린다.
anchorPoint의 단위는 unit이다.

### Coordinate Systems

레이어는 계층적구조를 가지며, 각 레이어 트리의 상위에 배치된다.
레이어의 Position은 슈퍼레이어의 bounds 속성에 상대적이며, 슈퍼레이어를 움직이면 하위 레이어들도 이동하기 때문에 되게 편리함.
그러나 때로는 슈퍼레이어 말고 다른 레이어와의 상대적인 위치를 알고싶은 경우가 있는데 이 때 CALayer는 이를위한 몇몇가지 메소드를 제공해준다.

- CALayer().convert(p: CGPoint CGPoint, to:
- CALayer().convert(p: CGPoint CGPoint, from: CALayer?)
- CALayer().convert(r: CGRect CGRect, to: CALayer?)
- CALayer().convert(r: CGRect CGRect, from: CALayer?)

### Flipped Geometry

일반적으로 iOS의 하위 레이어들은 슈퍼 레이어의 상단 왼쪽 모서리 부분을 기준으로 배치가 된다.(Mac OS의 경우 하단 왼쪽 위치가 기준이다.)
그러나 iOS도 Mac과 마찬가지로 하단 왼쪽 모서리를 기준으로 배치할 수 있게 geometryFlipped 라는 프로퍼티를 제공한다.
geometryFlipped속성이 true일 경우 레이어들은 하단 왼쪽 위치를 기준으로 배치된다.

### The Z Axis

2차원 평면의 UIView와 달리 CALayer는 3차원적인 구조를 갖는다.(x, y 뿐 만 아니라 z 에 대한 것도 지원)
zPosion을 이용해서 layer의 표시 순서를 변경할 수 있다.

### HitTesting

CALayer는 UIResponder체인의 존재를 모르고 실질적으로 이벤트를 처리하는 로직이 없다. 하지만 이벤트를 처리하는 로직을 위한 몇가지 함수를 제공한다.

- contains: Point -> Bool : 특정 Point가 자신의 레이어 안에 있는지 확인한다.
- hitTest: Point -> CALayer? : 특정 Point의 최하위 레이어를 반환한다.
  - hitTest와 관련해서 앞서 zPosition이라는 것을 배웠는데, 이것은 표시 순서만 바뀔 뿐 실질적인 터치 이벤트 처리에 대한 순서는 바꿔주지 않는다. 따라서 최하위레이어의 상위 레이어의 zPosition을 변경하여
앞에 표시하여도 터치 이벤트에 대해서는 최하위레이어를 반환한다.