
import MapKit

class TileCoordinateOverlay: MKTileOverlay {

    /// Use a 2 x 2 grid of colors so the same color is never adjacent to itself, to make the tile boundaries obvious.
    private let tileColors = [ [#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 0.7), #colorLiteral(red: 0.9921568627, green: 0.6823529411, blue: 0.0039215686, alpha: 0.7)],
                               [#colorLiteral(red: 1.0000000000, green: 0.9450980392, blue: 0.3372549019, alpha: 0.7), #colorLiteral(red: 0.5499670582, green: 0.9739212428, blue: 0.2905708413, alpha: 0.7)] ]

    override func loadTile(at path: MKTileOverlayPath) async throws -> Data {
        /**
         Usually, you provide prerendered tiles and either load them from disk or the network rather than creating them on-demand, as they are here.
         Because the purpose of this tile overlay is to visualize the tile paths and zoom levels for all tiles worldwide, providing a prerendererd
         tile set for the entire world is infeasible.
         */
        let renderer = UIGraphicsImageRenderer(size: tileSize)
        let data = renderer.pngData { context in

            let color = tileColors[path.x % 2][path.y % 2]
            color.setFill()
            context.fill(CGRect(origin: .zero, size: tileSize))

            let text = """
                        Tile Path (\(path.x), \(path.y))
                        Zoom: \(path.z)
                       """

            let rect = CGRect(origin: CGPoint(x: 10, y: 10), size: tileSize)
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)]
            text.draw(in: rect, withAttributes: attributes)
        }

        return data
    }
}
