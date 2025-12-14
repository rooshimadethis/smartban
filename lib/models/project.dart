import 'dart:ui';

class Project {
  final String id;
  final String name;
  final Color color;

  const Project({required this.id, required this.name, required this.color});

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color.toARGB32()};
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
    );
  }
}
