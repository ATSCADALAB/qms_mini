// lib/models/queue_item.dart
class QueueItem {
  final int? id;
  final int number;
  final String prefix;
  final String status; // waiting, serving, called, completed, skipped, deleted
  final int priority;
  final DateTime createdDate;
  final DateTime createdTime;
  final DateTime? calledTime;
  final DateTime? servedTime;
  final String operator;
  final String? notes;
  final bool synced;

  QueueItem({
    this.id,
    required this.number,
    required this.prefix,
    required this.status,
    this.priority = 0,
    required this.createdDate,
    required this.createdTime,
    this.calledTime,
    this.servedTime,
    required this.operator,
    this.notes,
    this.synced = false,
  });

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'number': number,
      'prefix': prefix,
      'status': status,
      'priority': priority,
      'created_date': createdDate.toIso8601String().split('T')[0],
      'created_time': createdTime.toIso8601String(),
      'called_time': calledTime?.toIso8601String(),
      'served_time': servedTime?.toIso8601String(),
      'operator': operator,
      'notes': notes,
      'synced': synced ? 1 : 0,
    };
  }

  // Create from SQLite Map
  factory QueueItem.fromMap(Map<String, dynamic> map) {
    return QueueItem(
      id: map['id'],
      number: map['number'],
      prefix: map['prefix'] ?? 'A',
      status: map['status'] ?? 'waiting',
      priority: map['priority'] ?? 0,
      createdDate: DateTime.parse(map['created_date']),
      createdTime: DateTime.parse(map['created_time']),
      calledTime: map['called_time'] != null ? DateTime.parse(map['called_time']) : null,
      servedTime: map['served_time'] != null ? DateTime.parse(map['served_time']) : null,
      operator: map['operator'] ?? 'system',
      notes: map['notes'],
      synced: (map['synced'] ?? 0) == 1,
    );
  }

  // Copy with changes
  QueueItem copyWith({
    int? id,
    int? number,
    String? prefix,
    String? status,
    int? priority,
    DateTime? createdDate,
    DateTime? createdTime,
    DateTime? calledTime,
    DateTime? servedTime,
    String? operator,
    String? notes,
    bool? synced,
  }) {
    return QueueItem(
      id: id ?? this.id,
      number: number ?? this.number,
      prefix: prefix ?? this.prefix,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdDate: createdDate ?? this.createdDate,
      createdTime: createdTime ?? this.createdTime,
      calledTime: calledTime ?? this.calledTime,
      servedTime: servedTime ?? this.servedTime,
      operator: operator ?? this.operator,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
    );
  }

  // For MQTT messages
  Map<String, dynamic> toMqttPayload() {
    return {
      'number': number,
      'prefix': prefix,
      'status': status,
      'priority': priority,
      'created_time': createdTime.toIso8601String(),
      'called_time': calledTime?.toIso8601String(),
      'served_time': servedTime?.toIso8601String(),
      'operator': operator,
      'notes': notes,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Create from MQTT payload
  factory QueueItem.fromMqttPayload(Map<String, dynamic> payload) {
    return QueueItem(
      number: payload['number'],
      prefix: payload['prefix'] ?? 'A',
      status: payload['status'] ?? 'waiting',
      priority: payload['priority'] ?? 0,
      createdDate: DateTime.now(),
      createdTime: DateTime.parse(payload['created_time']),
      calledTime: payload['called_time'] != null ? DateTime.parse(payload['called_time']) : null,
      servedTime: payload['served_time'] != null ? DateTime.parse(payload['served_time']) : null,
      operator: payload['operator'] ?? 'remote',
      notes: payload['notes'],
      synced: true, // From MQTT means already synced
    );
  }

  // Generate display number (A001, B025, etc.)
  String get displayNumber => '$prefix${number.toString().padLeft(3, '0')}';

  // Check if item is active (not completed/skipped/deleted)
  bool get isActive => !['completed', 'skipped', 'deleted'].contains(status.toLowerCase());

  // Get status display text in Vietnamese
  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'waiting':
        return 'Đang chờ';
      case 'serving':
        return 'Đang phục vụ';
      case 'called':
        return 'Đã gọi';
      case 'completed':
        return 'Hoàn thành';
      case 'skipped':
        return 'Bỏ qua';
      case 'deleted':
        return 'Đã xóa';
      default:
        return status;
    }
  }

  // Get priority display text
  String get priorityDisplayText {
    switch (priority) {
      case 0:
        return 'Bình thường';
      case 1:
        return 'Ưu tiên';
      case 2:
        return 'Khẩn cấp';
      default:
        return 'Mức $priority';
    }
  }

  @override
  String toString() {
    return 'QueueItem{id: $id, displayNumber: $displayNumber, status: $status, priority: $priority}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is QueueItem &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              number == other.number &&
              prefix == other.prefix;

  @override
  int get hashCode => id.hashCode ^ number.hashCode ^ prefix.hashCode;
}