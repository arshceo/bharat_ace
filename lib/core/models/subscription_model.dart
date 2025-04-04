import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class Subscription {
  String studentId;
  bool isActive;
  String planType; // Monthly, Yearly
  double amountPaid;
  DateTime startDate;
  DateTime endDate;

  Subscription({
    required this.studentId,
    required this.isActive,
    required this.planType,
    required this.amountPaid,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() => {
        "studentId": studentId,
        "isActive": isActive,
        "planType": planType,
        "amountPaid": amountPaid,
        "startDate": startDate,
        "endDate": endDate,
      };

  factory Subscription.fromMap(Map<String, dynamic> map) => Subscription(
        studentId: map["studentId"],
        isActive: map["isActive"],
        planType: map["planType"],
        amountPaid: map["amountPaid"],
        startDate: (map["startDate"] as Timestamp).toDate(),
        endDate: (map["endDate"] as Timestamp).toDate(),
      );
}
