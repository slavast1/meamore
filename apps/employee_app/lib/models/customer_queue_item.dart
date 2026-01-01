class CustomerQueueItem {
  CustomerQueueItem({
    required this.id,
    required this.dogName,
    required this.breed,
    required this.ownerFullName,
    this.day,
    this.startTime,
    this.endTime,
    this.customerMobile,
    this.serviceTitle,
    this.empName,
    this.dogsNumber,
    this.remark,
  });

  /// Stable identifier coming from the REST API (appointments payload `id`).
  final String id;

  // Core data shown in the queue and used to create treatments.
  final String dogName;
  final String breed;
  final String ownerFullName;

  // Optional fields coming from the REST API (appointments payload)
  final String? day; // yyyy-MM-dd
  final String? startTime; // HH:mm
  final String? endTime; // HH:mm
  final String? customerMobile;
  final String? serviceTitle;
  final String? empName;
  final int? dogsNumber;
  final String? remark;
}
