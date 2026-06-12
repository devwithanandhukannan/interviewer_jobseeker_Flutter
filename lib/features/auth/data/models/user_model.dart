class UserModel {
  final String fullName;
  final String email;
  final String phoneNumber;

  UserModel({required this.fullName, required this.email, required this.phoneNumber});

  factory UserModel.fromJson(Map<String, dynamic> json){
    final profile = json['user']?['jobSeekerProfile'] as Map<String,dynamic>?;

    return UserModel(fullName: profile?['fullName']??' ', email: profile?['email']??'', phoneNumber: profile?['phone']??'');
  }
}

