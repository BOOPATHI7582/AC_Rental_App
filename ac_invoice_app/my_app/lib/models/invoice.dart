class InvoiceItem {
  String itemName;
  String unit; // e.g. Nos, Ton
  double quantity;
  double price; // price per unit
  double igstPercent; // e.g. 18 for 18%

  InvoiceItem({
    this.itemName = '',
    this.unit = 'Nos',
    this.quantity = 1,
    this.price = 0,
    this.igstPercent = 18,
  });

  // Taxable / Amount = Quantity * Price
  double get taxableAmount => quantity * price;

  double get igstAmount => taxableAmount * igstPercent / 100;

  // Total amount for this row = taxable amount + igst
  double get totalAmount => taxableAmount + igstAmount;

  Map<String, dynamic> toJson() => {
        'itemName': itemName,
        'unit': unit,
        'quantity': quantity,
        'price': price,
        'igstPercent': igstPercent,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        itemName: json['itemName'] as String? ?? '',
        unit: json['unit'] as String? ?? 'Nos',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        igstPercent: (json['igstPercent'] as num?)?.toDouble() ?? 18,
      );
}

class Invoice {
  String id;
  String invoiceNo;
  DateTime date;
  String clientId;
  List<InvoiceItem> items;
  double receivedAmount;
  String notes;
  DateTime? lastReminderAt;
  DateTime? rentalStartDate;
  DateTime? rentalEndDate;

  Invoice({
    required this.id,
    required this.invoiceNo,
    required this.date,
    required this.clientId,
    List<InvoiceItem>? items,
    this.receivedAmount = 0,
    this.notes = '',
    this.lastReminderAt,
    this.rentalStartDate,
    this.rentalEndDate,
  }) : items = items ?? [];

  double get subTotal => items.fold(0.0, (s, i) => s + i.taxableAmount);

  double get totalIgst => items.fold(0.0, (s, i) => s + i.igstAmount);

  double get totalAmount => subTotal + totalIgst;

  double get balanceAmount => totalAmount - receivedAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNo': invoiceNo,
        'date': date.toIso8601String(),
        'clientId': clientId,
        'items': items.map((e) => e.toJson()).toList(),
        'receivedAmount': receivedAmount,
        'notes': notes,
        'lastReminderAt': lastReminderAt?.toIso8601String(),
        'rentalStartDate': rentalStartDate?.toIso8601String(),
        'rentalEndDate': rentalEndDate?.toIso8601String(),
      };

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as String,
        invoiceNo: json['invoiceNo'] as String,
        date: DateTime.parse(json['date'] as String),
        clientId: json['clientId'] as String,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        receivedAmount: (json['receivedAmount'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String? ?? '',
        lastReminderAt: json['lastReminderAt'] != null
            ? DateTime.tryParse(json['lastReminderAt'] as String)
            : null,
        rentalStartDate: json['rentalStartDate'] != null
            ? DateTime.tryParse(json['rentalStartDate'] as String)
            : null,
        rentalEndDate: json['rentalEndDate'] != null
            ? DateTime.tryParse(json['rentalEndDate'] as String)
            : null,
      );
}
