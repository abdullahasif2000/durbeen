import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.orange[700],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          centerTitle: true,
          title: const Text(
            ' Campus Connect',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 24,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/durbeen-logo.png',
              height: 120,
            ),
            const SizedBox(height: 30),

            const Text(
              'Login To Your Account',
              style: TextStyle(fontSize: 20,fontWeight:FontWeight.w700),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const Divider(),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: InputBorder.none,
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),


            ElevatedButton(
              onPressed: () {
                String email = emailController.text;
                String password = passwordController.text;


                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Email: $email, Password: $password')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(height: 20),
            const Text(
              '© 2024. All rights reserved.',
              style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
