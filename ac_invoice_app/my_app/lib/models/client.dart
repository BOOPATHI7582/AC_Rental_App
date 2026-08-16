class Client {
  String id;
  String name;
  String address;
  String phone;
  String gstin;
  String state;

  Client({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.gstin = '',
    this.state = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'gstin': gstin,
        'state': state,
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        gstin: json['gstin'] as String? ?? '',
        state: json['state'] as String? ?? '',
      );
}
