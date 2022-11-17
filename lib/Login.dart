import 'package:flutter/material.dart';
import 'package:hello_me/auth_repository.dart';
import 'package:provider/provider.dart';
import 'package:hello_me/signUp.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});


  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Login'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: <Widget>[
              const SizedBox(height: 10),
              const Text(
                  'Welcome to Startup Names Generator, please log in below',
                  style: TextStyle(fontSize: 12,)
              ),
              TextField(
                decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail, color: Colors.black),
                ),
                controller: emailController,
              ),
              const SizedBox(height: 5),
              TextField(
                decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: Colors.black),
                ),
                obscureText: true,
                controller: passwordController,
              ),
              Consumer<AuthRepository>(
                builder: (context, authRep, child){
                  return ElevatedButton(
                    onPressed:  () async{
                      if (authRep.status == Status.Authenticating) {}
                      else {
                        var tmp = await authRep.signIn(emailController.text, passwordController.text);
                        if (tmp == true){
                          Navigator.of(context).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('There was an error logging into the app')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(30), backgroundColor: authRep.status == Status.Authenticating?Colors.grey:Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text("Log in"),
                  );
                },
              ),

              SignUpButton(userEmailController:emailController, userPasswordController:passwordController).build(context)
            ],
          )
      ),
    );
  }

}