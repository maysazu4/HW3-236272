import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hello_me/auth_repository.dart';
import 'package:provider/provider.dart';

class SignUpButton extends StatelessWidget {
  final userEmailController;
  final userPasswordController;

  SignUpButton({Key? key, required this.userEmailController, required this.userPasswordController})
      : super(key: key);

  @override

  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return PasswordConfirmSheet(
                userEmailController: userEmailController,
                userPasswordController: userPasswordController,
              );
            });
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(30), backgroundColor: Colors.lightBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      child: const Text("New user? Click here to sign up"),
    );
  }

 }

class PasswordConfirmSheet extends StatefulWidget {
  final userEmailController;
  final userPasswordController;


  PasswordConfirmSheet(
      {Key? key, required this.userEmailController, required this.userPasswordController})
      : super(key: key);

  @override
  _PasswordConfirmSheetState createState() =>
      _PasswordConfirmSheetState(userEmailController, userPasswordController);


}

class _PasswordConfirmSheetState extends State<PasswordConfirmSheet> {
  final _confirmController = TextEditingController();
  final emailController;
  final passwordController;
  bool _isValid = true;

  _PasswordConfirmSheetState(this.emailController, this.passwordController);

  @override
  Widget build(BuildContext context,) {
    return Consumer<AuthRepository>(builder: (context, authRep, child){
      return Padding(
        padding: MediaQuery
            .of(context)
            .viewInsets,
        child: Container(
          height: 260,
          child: Column(
            children: [
              Container(
                  padding: const EdgeInsets.all(10.0),
                  child: const ListTile(
                      title: Text("Please confirm your password below:", textAlign: TextAlign.center,))),
              const Divider(),
              Container(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    decoration: InputDecoration(
                        labelText: 'Password',
                        errorText: _isValid ? null : "Passwords must match"
                    ),
                    controller: _confirmController,
                    obscureText: true,

                  )),
              const Divider(),
              ElevatedButton(
                  onPressed: () => checkValid(authRep),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                  ),
                  child: const Text("Confirm")
              )
            ],
          ),
        ),
      );
    });
  }

  void checkValid(AuthRepository authRep) {
    if (_confirmController.text == passwordController.text) {
      authRep.signUp(emailController.text, passwordController.text).then((value) {
        if (value != null) {
          FirebaseFirestore.instance.collection('Hw3').doc(
              "data").collection("users")
              .doc(authRep.user!.uid)
              .update(
              {"avatar": ""})
              .then((value) {});
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          setState(() {
            _isValid = true;
          }
          );
        }
      },);

    } else {
      setState(() {
        _isValid = false;
      });
    }
  }


}
