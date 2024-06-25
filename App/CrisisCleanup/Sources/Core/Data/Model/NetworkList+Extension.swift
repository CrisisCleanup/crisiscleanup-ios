extension NetworkList {
    func asRecord() -> ListRecord {
        ListRecord(
            networkId: id,
            localGlobalUuid: "",
            createdBy: createdBy,
            updatedBy: updatedBy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            parent: parent,
            name: name,
            description: description,
            listOrder: listOrder,
            tags: tags,
            model: model,
            objectIds: (objectIds ?? []).map { String($0) }.joined(separator: ","),
            shared: shared,
            permissions: permissions,
            incidentId: incident
        )
    }
}
