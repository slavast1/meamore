class QueueCustomer {
  QueueCustomer({
    required this.dogName,
    required this.breed,
    required this.ownerFullName,
  });

  final String dogName;
  final String breed;
  final String ownerFullName;
}

abstract class QueueApi {
  Future<List<QueueCustomer>> fetchQueue();
}

/// Simulator until real REST API is ready.
class QueueApiSimulator implements QueueApi {
  @override
  Future<List<QueueCustomer>> fetchQueue() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return [
      QueueCustomer(dogName: 'Luna', breed: 'Poodle', ownerFullName: 'Noam Levi'),
      QueueCustomer(dogName: 'Max', breed: 'Golden Retriever', ownerFullName: 'Dana Cohen'),
      QueueCustomer(dogName: 'Bella', breed: 'Mixed', ownerFullName: 'Eyal Mizrahi'),
    ];
  }
}
