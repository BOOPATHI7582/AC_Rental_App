class CompanySettings {
  String companyName;
  String tagline;
  String address;
  String phone;
  String email;
  String gstin;
  String state;

  // Local file paths (copied into app documents directory)
  String? logoPath;
  String? signaturePath;

  // Bank details
  String bankName;
  String bankBranch;
  String accountNumber;
  String ifscCode;
  String accountHolderName;

  // Terms & conditions (multi-line free text)
  String termsAndConditions;

  // Running invoice counter used to auto-suggest the next invoice number
  int nextInvoiceNumber;

  CompanySettings({
    this.companyName = 'Your AC Rental Company',
    this.tagline = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.gstin = '',
    this.state = 'Tamil Nadu',
    this.logoPath,
    this.signaturePath,
    this.bankName = '',
    this.bankBranch = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.accountHolderName = '',
    this.termsAndConditions =
        'Goods once given on rent must be returned in good condition.\n'
        'Any dispute subject to Tiruppur jurisdiction.\n'
        'If bill is paid after due date, interest will be charged.\n'
        'Any damage during transit is not our responsibility unless wooden packed.',
    this.nextInvoiceNumber = 1,
  });

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'tagline': tagline,
        'address': address,
        'phone': phone,
        'email': email,
        'gstin': gstin,
        'state': state,
        'logoPath': logoPath,
        'signaturePath': signaturePath,
        'bankName': bankName,
        'bankBranch': bankBranch,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'accountHolderName': accountHolderName,
        'termsAndConditions': termsAndConditions,
        'nextInvoiceNumber': nextInvoiceNumber,
      };

  factory CompanySettings.fromJson(Map<String, dynamic> json) => CompanySettings(
        companyName: json['companyName'] as String? ?? 'Your AC Rental Company',
        tagline: json['tagline'] as String? ?? '',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        gstin: json['gstin'] as String? ?? '',
        state: json['state'] as String? ?? 'Tamil Nadu',
        logoPath: json['logoPath'] as String?,
        signaturePath: json['signaturePath'] as String?,
        bankName: json['bankName'] as String? ?? '',
        bankBranch: json['bankBranch'] as String? ?? '',
        accountNumber: json['accountNumber'] as String? ?? '',
        ifscCode: json['ifscCode'] as String? ?? '',
        accountHolderName: json['accountHolderName'] as String? ?? '',
        termsAndConditions: json['termsAndConditions'] as String? ?? '',
        nextInvoiceNumber: json['nextInvoiceNumber'] as int? ?? 1,
      );
}
