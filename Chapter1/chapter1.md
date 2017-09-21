## The Layer Tree

UIView handles touch events and support graphics-based drawing, affine transform, and simple animation such as sliding and fading.

UIView does not deal with most of these tasks itself.
Rendering, layout, and animation are all managed by a Core animation class called CALayer.

### Layers and Views

#### CALayer

The CALayer class is conceptually very similar to UIView. Layers are rectangular objects that can be arranged into a hierarchical tree. and manage the position of their children(sublayers).
The only major feature of UIView that is not handled by CALayer is user interaction

CALayer는 UIView처럼 사용자의 이벤트를 처리하지 않으며, 단순히 터치 이벤트가 자기 자신의 바운드에 들어왔는지 확인해주는 메소드를 제공해준다.

모든 UIView 들은 layer(CALayer의 인스턴스)라는 프로퍼티를 갖는다. 이것은 backing layer로 알려져있다.

스크린에 보여지는 모든 에니메이션과 디스플레이에 대하여 backing layer가 책임진다.
UIView는 랩핑한거임. 터치핸들링과 같은 iOS의 특별한 함수를 재공해주는..(하이레벨)
그리고 core animation은 로우레벨 평션임..

왜 iOS는 UIView와 CALayer라는 두개의 베럴러한 계층을 갖을까?
왜 모든것을 처리하는 1단 계층 구조가 아닐까?
이유는 책임을 분리하고, 중복 코드를 회피하기 위해서이다.

멀티터치는 마우스와 키보드와같은 것과 패러다임이 다르다.
그러므로 iOS는 UIKit를.. Mac OS는 AppKit과 NSView를 갖는다. 이 두개는 매우 유사하지만 실제 구현은 현저하게 다르다.

Core Animation으로 분리되어있는 로직을은 iOS와 Mac OS에서 공유해서 사용할 수 있다.

#### Layer Capabilities

So if CALayer is just an implementation detail of the inner workings of UIView, why do we need to know about it at all? Surely Apple provides the nice, simple UIView interface precisely so that we don’t need to deal directly with gnarly details of Core Animation itself?

그렇다. 우리는 CALayer에 다이렉트로 접근할 필요가 없다.애플은 되게 파워풀하게 만들었다. UIView를 통해서 animation을 간접적으로 조절할수있다. 높은 레벨의 APIs를 사용해서.

UIView에는 없고 CALayer에는 있는 몇몇 특징
- Drop shadows, rounded corners, and colored borders
- 3D transforms and positioning ▪ Nonrectangular bounds ▪ Alpha masking of content
- Multistep, nonlinear animations

뷰는 오직 한 개의 backing layer를 갖고있으며. 여러 레이어들을 무한하개 갖을 수 있다.
그러나 backing layer에 다른 레이어를 추가하는 것은 성능에 영향을 줄 수 있다.

호스팅된 레이어를 사용하는 경우는 다음과 같은 것들이 있다.
-  You might be writing cross-platform code that will also need to work on a Mac.  
-  You might be working with multiple CALayer subclasses(seeChapter6, “Specialized Layers”) and have no desire to create new UIView subclasses to host them all.  
-  You might be doing such performance-critical work that even the negligible overhead of maintaining the extra UIView object makes a measurable difference (although in that case, you’ll probably want to use something like OpenGL for your drawing anyway).  
결국 backing layer에서 처리할 수 있는 것들은 여기서 처리하는것이 성능을 올릴 수 있다.