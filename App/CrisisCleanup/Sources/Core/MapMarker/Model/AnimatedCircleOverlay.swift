import CoreLocation
import MapKit

private func getBoundingMapRect(
    _ center: CLLocationCoordinate2D,
    _ radius: Double
) -> MKMapRect {
    let mapPointRadius = radius * MKMapPointsPerMeterAtLatitude(center.latitude)
    let mapPointDiameter = mapPointRadius * 2
    let origin = MKMapPoint(center)
    return MKMapRect(
        x: origin.x - mapPointRadius,
        y: origin.y - mapPointRadius,
        width: mapPointDiameter,
        height: mapPointDiameter
    )
}

extension MKOverlayRenderer {
    func getBoundingRect(_ circle: AnimatedCircleOverlay) -> CGRect {
        let ppm = MKMapPointsPerMeterAtLatitude(circle.coordinate.latitude)
        let mapPointRadius = circle.currentRadius * ppm
        let mapPointDiameter = mapPointRadius * 2
        let centerPoint = point(for: MKMapPoint(circle.coordinate))
        return CGRect(
            x: centerPoint.x - mapPointRadius,
            y: centerPoint.y - mapPointRadius,
            width: mapPointDiameter,
            height: mapPointDiameter,
        )
    }
}

class AnimatedCircleOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D

    // TODO: Does not draw over adjacent tiles at times
    private(set) var boundingMapRect: MKMapRect

    var targetRadius: CLLocationDistance

    private var _currentRadius: CLLocationDistance
    var currentRadius: CLLocationDistance {
        get { return _currentRadius }
        set {
            _currentRadius = newValue
            updateBoundingRect()
        }
    }

    init(center: CLLocationCoordinate2D, radius: CLLocationDistance) {
        coordinate = center
        targetRadius = radius
        _currentRadius = radius

        self.boundingMapRect = getBoundingMapRect(coordinate, radius)

        super.init()
    }

    private func updateBoundingRect() {
        self.boundingMapRect = getBoundingMapRect(coordinate, currentRadius)
    }
}

class AnimatedCircleRenderer: MKOverlayRenderer {
    let fillColor: UIColor
    let strokeColor: UIColor
    let lineWidth: CGFloat

    init(
        _ overlay: AnimatedCircleOverlay,
        fillColor: UIColor,
        strokeColor: UIColor,
        lineWidth: CGFloat,
    ) {
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in ctx: CGContext) {
        guard let circle = overlay as? AnimatedCircleOverlay else {
            return
        }

        let path = CGMutablePath()
        path.addEllipse(in: getBoundingRect(circle))
        ctx.addPath(path)

        ctx.setFillColor(fillColor.cgColor)
        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.setLineWidth(lineWidth / zoomScale)
        ctx.drawPath(using: .fillStroke)
    }
}

class CircleAnimationManager: ObservableObject {
    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0
    var animationDuration: CFTimeInterval = 0.3
    private var startRadius: CLLocationDistance = 0
    private var targetRadius: CLLocationDistance = 0

    weak var circle: AnimatedCircleOverlay?
    weak var renderer: AnimatedCircleRenderer?

    deinit {
        stopAnimation()
    }

    func animateRadius(to newRadius: CLLocationDistance) {
        guard let circle = circle else {
            return
        }

        guard targetRadius != newRadius else {
            return
        }

        stopAnimation()

        startRadius = circle.currentRadius
        targetRadius = newRadius
        circle.targetRadius = newRadius

        animationStartTime = CACurrentMediaTime()

        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .current, forMode: .common)
    }

    @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
        guard let circle = circle else {
            return
        }

        let elapsed = CACurrentMediaTime() - animationStartTime
        let progress = min(elapsed / animationDuration, 1.0)

        let newRadius = startRadius + (targetRadius - startRadius) * easingScale(progress)
        circle.currentRadius = newRadius

        renderer?.setNeedsDisplay()

        if progress >= 1.0 {
            stopAnimation()
            circle.currentRadius = targetRadius
            renderer?.setNeedsDisplay()
        }
    }

    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func easingScale(_ t: Double) -> Double {
        1 - pow(1 - t, 3)
    }
}
