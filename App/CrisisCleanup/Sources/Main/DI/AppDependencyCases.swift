extension MainComponent {
    public var incidentBoundsProvider: IncidentBoundsProvider {
        shared {
            MapsIncidentBoundsProvider(
                incidentsRepository: incidentsRepository,
                locationsRepository: locationsRepository
            )
        }
    }
}
