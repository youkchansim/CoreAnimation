import UIKit
import PlaygroundSupport

class LayerTree: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let blueLayer = CALayer()
        blueLayer.frame = rect
        blueLayer.backgroundColor = UIColor.blue.cgColor
        
        layer.addSublayer(blueLayer)
    }
}

let container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))

let view = LayerTree(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
container.addSubview(view)

PlaygroundPage.current.liveView = container
