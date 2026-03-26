import AppIntents

struct WidgetSubjectEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Subject"
    static let defaultQuery = WidgetSubjectQuery()

    let id: String
    let name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init(snapshot: WidgetSubjectSnapshot) {
        self.init(id: snapshot.id, name: snapshot.name)
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: name)
    }
}

struct WidgetSubjectQuery: EntityQuery {
    func entities(for identifiers: [WidgetSubjectEntity.ID]) async throws -> [WidgetSubjectEntity] {
        allSubjects().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [WidgetSubjectEntity] {
        allSubjects()
    }

    private func allSubjects() -> [WidgetSubjectEntity] {
        (WidgetSnapshotStore.load()?.subjectSummaries ?? [])
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            .map(WidgetSubjectEntity.init(snapshot:))
    }
}

struct SubjectGraphConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Subject Graph" }
    static var description: IntentDescription { "Choose which subject trend the widget should display." }

    @Parameter(title: "Subject")
    var subject: WidgetSubjectEntity?
}
