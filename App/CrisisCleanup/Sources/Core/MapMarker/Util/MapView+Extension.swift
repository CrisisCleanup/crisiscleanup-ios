import MapKit

private let reuseIdentifier = "reuse-identifier"

class CustomPinAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    let image: UIImage?
    let id: String

    init(
        _ coordinate: CLLocationCoordinate2D,
        image: UIImage? = nil,
        id: String = ""
    ) {
        self.coordinate = coordinate
        self.image = image
        self.id = id
        super.init()
    }
}

extension MKMapView {
    func animateToCenter(
        _ center: CLLocationCoordinate2D,
        zoomLevel: Int = 11
    ) {
        let zoom = zoomLevel < 0 || zoomLevel > 20 ? 9 : zoomLevel

        // An approximation. Based off tile zoom level.
        let zoomScale = 1.0 / pow(2.0, Double(zoom))
        let latDelta = 180.0 * zoomScale
        let longDelta = 360.0 * zoomScale
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        if span.isValid {
            let center = CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude)
            let regionCenter = MKCoordinateRegion(center: center, span: span)
            let region = regionThatFits(regionCenter)
            setRegion(region, animated: true)
        }
    }

    func makeOverlayPolygons() -> [MKPolygon] {
        let firstHalf = [
            CLLocationCoordinate2D(latitude: -90, longitude: -180),
            CLLocationCoordinate2D(latitude: -90, longitude: 0),
            CLLocationCoordinate2D(latitude: 90, longitude: 0),
            CLLocationCoordinate2D(latitude: 90, longitude: -180)
        ]

        let secondHalf = [
            CLLocationCoordinate2D(latitude: 90, longitude: 0),
            CLLocationCoordinate2D(latitude: 90, longitude: 180),
            CLLocationCoordinate2D(latitude: -90, longitude: 180),
            CLLocationCoordinate2D(latitude: -90, longitude: 0)
        ]

        let negativePolygon = MKPolygon(coordinates: firstHalf, count: firstHalf.count)
        let positivePolygon = MKPolygon(coordinates: secondHalf, count: secondHalf.count)

        return [negativePolygon, positivePolygon]
    }

    func addOverlays(
        _ overlays: [MKOverlay],
        level: MKOverlayLevel = .aboveRoads
    ) {
        overlays.forEach {
            addOverlay($0, level: level)
        }
    }

    func configure(
        isScrollEnabled: Bool = false,
        isExistingMap: Bool = false,
        isSatelliteView: Bool = false,
    ) {
        configure(
            overlays: isSatelliteView ? [] : makeOverlayPolygons(),
            isScrollEnabled: isScrollEnabled,
            isExistingMap: isExistingMap,
            isSatelliteView: isSatelliteView,
        )
    }

    func configure(
        overlays: [MKOverlay],
        isScrollEnabled: Bool = false,
        isExistingMap: Bool = false,
        isSatelliteView: Bool = false,
    ) {
        overrideUserInterfaceStyle = .light
        setSatelliteMapType(isSatelliteView)
        pointOfInterestFilter = .excludingAll
        if !isExistingMap {
            camera.centerCoordinateDistance = 20
        }
        isRotateEnabled = false
        isPitchEnabled = false
        self.isScrollEnabled = isScrollEnabled

        addOverlays(overlays)
    }

    func staticMapAnnotationView(
        _ annotation: MKAnnotation,
        imageHeightOffsetWeight: CGFloat = -0.5
    ) -> MKAnnotationView? {
        guard let annotationView = dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) else {
            if let annotation = annotation as? CustomPinAnnotation {
                let view = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                view.image = annotation.image
                if let annotationImage = annotation.image,
                   imageHeightOffsetWeight != 0 {
                    view.centerOffset = CGPointMake(0, annotationImage.size.height * imageHeightOffsetWeight)
                }
                return view
            }
            return nil
        }
        return annotationView
    }

    func reusableAnnotationView(
        _ annotation: MKAnnotation,
        imageHeightOffsetWeight: CGFloat = -0.5
    ) -> MKAnnotationView? {
        var identifier = reuseIdentifier
        var image: UIImage? = nil
        if let customAnnotation = annotation as? CustomPinAnnotation {
            identifier = customAnnotation.id
            image = customAnnotation.image
        }

        guard let annotationView = dequeueReusableAnnotationView(withIdentifier: identifier) else {
            if let annotationImage = image {
                let view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.image = annotationImage
                view.centerOffset = CGPointMake(0, annotationImage.size.height * imageHeightOffsetWeight)
                return view
            }
            return nil
        }
        return annotationView
    }
}

func overlayMapRenderer(
    _ polygon: MKPolygon,
    _ alpha: Double = 0.6,
    _ color: UIColor = .black
) -> MKPolygonRenderer {
    let renderer = MKPolygonRenderer(polygon: polygon)
    renderer.alpha = alpha
    renderer.lineWidth = 0
    renderer.fillColor = color
    renderer.blendMode = .color
    return renderer
}

func overlayCircleRenderer(
    _ circle: MKCircle,
    strokeColor: UIColor,
    fillColor: UIColor,
    strokeWidth: Double = 4.0,
) -> MKCircleRenderer {
    let renderer = MKCircleRenderer(circle: circle)
    renderer.lineWidth = strokeWidth
    renderer.strokeColor = strokeColor
    renderer.fillColor = fillColor
    return renderer
}

class BlankRenderer: MKOverlayRenderer {
    override func canDraw(_ mapRect: MKMapRect, zoomScale: MKZoomScale) -> Bool {
        false
    }
}
