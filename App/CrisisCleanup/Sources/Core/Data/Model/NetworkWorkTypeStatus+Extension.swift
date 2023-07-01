extension NetworkWorkTypeStatusFull {
    func asRecord() -> WorkTypeStatusRecord {
        WorkTypeStatusRecord(
            id: status,
            name: name,
            listOrder: listOrder,
            primaryState: primaryState
        )
    }
}
