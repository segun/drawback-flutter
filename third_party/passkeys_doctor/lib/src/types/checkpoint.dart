class Checkpoint {
  const Checkpoint({
    required this.name,
    required this.description,
    required this.type,
    this.documentationLink,
  });

  final String name;
  final String description;
  final CheckpointType type;
  final String? documentationLink;

  @override
  String toString() {
    return 'Checkpoint: $name\n'
        'Description: $description\n'
        'Type: $type\n'
        'Documentation Link: ${documentationLink ?? "N/A"}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'type': type.toString(),
      'documentationLink': documentationLink,
    };
  }
}

enum CheckpointType { success, warning, error }
