class CustomerModel {
  final String name;

  CustomerModel({required this.name});

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(name: json['name']);
  }
}
