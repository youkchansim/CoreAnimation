# The backing Image

## The contents Image

CALayer는 contents라는 id타입의 프로퍼티를 갖는다. id타입으로 정의된 이유는 MacOS때문이다.
CGImage 혹은 NSImage를 할당할 수 있다. 만약 CGImage가 아닌 다른것을 적용한다면 빈 레이어가 보여질 것이다.

CGImage의 포인터인 CGImageRef를 적용하는것이 필요하다. UIImage는 CGImage프로퍼티를 갖으며 이것은 CGImageRef를 리턴시킨다.
CALayer contents에 CGImageRef를 할당하면 컴파일 에러가 난다. 왜냐하면 CGImageRef는 Cocoa object가 아니라 Core Foundation type이기 때문이다. 그러기 때문에 bridged cast가 필요하다.

### contentsGravity

CALayer에도 이미지를 추가할 때 UIImageView의 contentMode처럼 이미지 크기를 뷰에 맞게 조절할 수 있다.
contentsGravity라는 프로퍼티를 이용하여.. 얘는 스트링 이넘을 갖는다. 따라서 아래와 같은 스트링을 불러서 set해주면 됨.
- kCAGravityCenter
- kCAGravityTop
- kCAGravityBottom
- kCAGravityLeft
- kCAGravityRight
- kCAGravityTopLeft
- kCAGravityTopRight
- kCAGravityBottomLeft
- kCAGravityBottomRight
- kCAGravityResize
- kCAGravityResizeAspect
- kCAGravityResizeAspectFill

contentMode처럼 contentsGravity의 목적은 layer의 bounds내에서 content를 어떻게 정렬할 것인지 결정하는 것이다.
We will use kCAGravityResizeAspect, which equates to UIViewContentModeScaleAspectFit
self.layerView.layer.contentsGravity = kCAGravityResizeAspect

### contentsScale

UIView의 contentsScale프로퍼티는 layer’s backing image 의 픽셀 치수와 뷰의 사이즈 사이에 정의되는 비율이다. default는 1.0이며, contentsGravity에 의해서 layer bounds에 알맞게 스케일 되기때문에 대부분 사용자들은 따로 정의하지 않으면 스케일 업/다운에 대한 효과를 느낄 수 없다.
만약 레이어단에서 zoom을 하고 싶다면 layer’s transform or affineTransform 프로퍼티를 사용해야 한다. 이것이 contentsScale프로퍼티는 아니다.
contentsScale 프로퍼티는 고해상도를 지원하기 위한 매커니즘의 프로퍼티이다.
UIView는 이것과 동등한 contentScaleFactor라는 프로퍼티를 갖는다.
contentsScale가 1.0이면 1픽셀퍼 포인트의 해상도이고, 2.0이면 2픽셀 퍼 포인트이다.

When working with backing images that are generated programmatically, you’ll often need to remember to manually set the layer contentsScale to match the screen scale; otherwise, your images will appear pixelated on Retina devices. You do so like this:
layer.contentsScale = [UIScreen mainScreen].scale;

### masksToBounds

UIView에선 clipsToBounds라고 불리운다.(that is, to control whether a view’s contents are allowed to spill out of their frame).
CALayer에선 maksToBounds라고 불리운다.

### contentsRect

The contentsRect property of CALayer allows us to specify a subrectangle of the backing image to be displayed inside the layer frame. This allows for much greater flexibility than the contentsGravity property in terms of how the image is cropped and stretched.

- Points—The most commonly used coordinate type on iOS and Mac OS. Points are virtual pixels, also known as logical pixels. On standard-definition devices, 1 point equates to 1 pixel, but on Retina devices, a point equates to 2×2 physical pixels. iOS uses points for all screen coordinate measurements so that layouts work seamlessly on both Retina and non-Retina devices.

- ▪ Pixels—Physical pixel coordinates are not used for screen layout, but they are often still relevant when working with images. UIImage is screen-resolution aware, and specifies its size in points, but some lower-level image representations such as CGImage use pixel dimensions, so you should keep in mind that their stated size will not match their display size on a Retina device.

- ▪ Unit—Unit coordinates are a convenient way to specify measurements that are relative to the size of an image or a layer’s bounds, and so do not need to be adjusted if that size changes. Unit coordinates are used a lot in OpenGL for things like texture coordinates, and they are also used frequently in Core Animation.

### contentsCenter

위의 이름으로 추척하건데 content의 center 위치를 잡는것 같아 보이지만 실제로 이것은 center의 위치가 아니라
레이어 내부의 신축성있는 영역과 가장자리 주위의 고정 된 경계를 정의하는 CGRect입니다.

### Custom Drawing

drawRect에 대한 설명이 있다. Custom drawing을 하기 위해 대부분 개발자들은 이곳에 코드를 한다. 이것은 뷰가 나타날 때 불리게 되며, bounds의 변경등이 있을 때 setNeedsDisplay 함수 호출을 통해 다시 그릴 수 있다.
이것은 UIView의 기본 함수이기도 하지만 반드시 필수 구현해야하는 함수는 아니다. 애플은 해당 함수를 오버라이드 해서 빈 drawRect 호출하는것을 안하는것을 추천한다. 왜냐하면 메모리와 CPU 시간을 낭비하기 때문이다.
또한 drawRect 함수는 UIView의 함수일지라도 실제로 드로잉을 스케줄하고 결과 이미지를 저장하는 기본 CALayer이다.
layer는 display라는 함수를 호출하면 다시 그리는 것을 시작한다.

CALayer는 optical delegate인 CALayerDelegate프로토콜을 따른다.
몇몇 함수들이 있는데 그 중 두가지를 볼 것이다.

- (void)displayLayer:(CALayer *)layer;
  - 해당 레이어에 직접 무언가를 셋팅할 때 사용한다. 이 메소드가 불리지 않으면 아래의 메소드가 호출된다.

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
  - CALayer는 boudns와 contentsScale을 고려하여 알맞은 크기의 빈 backing image를 만든다. 그리고 Core Graphics를 이용해서 context에 알맞는 이미지를 그린다. 그때 사용하는 컨텍스트 레퍼런스가 ctx이다.

UIVIew와 다르게 CALayer는 자동적으로 Redraw를 하지 않기때문에 위의 델리게이트 함수 마지막에 layer.display를 호출한다. (Redraw의 결정권을 개발자에게 넘김.) 또한 masksToBounds를 false를 하여도 위의 델리게이트를 이용하여 구현한다면 이미지가 잘릴수도 있음. 왜냐하면 CALayer는 레이어의 정확한 크기로 드로잉 컨텍스트를 작성하기 때문입니다.
하지만 standalone layers를 사용하지 않는 한 위의 델리게이트 함수는 구현할 일이 거의 없다. 그 이유는 UIView가 레이어를 생성할 때 자동적으로 deleagte를 위임자로 지정하기 때문이다. 또한 UIView의 DrawRect는 자동적으로 Redraw를 해주기 때문에 이를 이용해서 구현하면 된다.