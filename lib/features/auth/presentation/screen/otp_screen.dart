import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/auth/presentation/controllers/auth_controller.dart';
import 'package:interviewer/features/dashboard/presentation/screen/home_screen.dart';

class OtpScreen extends ConsumerWidget{
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final otpFiledController = TextEditingController();
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: otpFiledController,
            decoration: const InputDecoration(
              hintText: "Enter otp"
            ),
          ),
          ElevatedButton(onPressed: ()async{
            final success = await ref.read(authControllerProvider.notifier).verifyOTP(otpFiledController.text);
            if(success){
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_)=> HomeScreen())
              );
            }
          }, child: Text('verify'))
        ],
      )
    );
  }

}