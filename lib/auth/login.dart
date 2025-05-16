import 'package:flutter/material.dart';
import 'package:music_app/auth/register.dart';
import 'package:music_app/pages/home_page.dart';
import 'package:music_app/services/auth_service.dart'; // Import the auth service

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Use the AuthService instead of direct Firebase references
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email and password sign in using AuthService
  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isLoading = true;
            _errorMessage = '';
      });
    });

      try {
        final userCredential = await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (userCredential.user != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {

        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          });
        });
        
      } finally {
        if (mounted) {

          WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _isLoading = false;
          });
        });
        }
      }
    }
  }

  // Google sign in using AuthService
  Future<void> _signInWithGoogle() async {

    WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
          _isLoading = true;
          _errorMessage = '';
          });
        });

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      // Navigate to home screen after successful login
      if (userCredential.user != null && mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const HomePage())
        );
      }
    } catch (e) {
      if (e.toString() != 'Exception: Sign in canceled by user') {
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
          _errorMessage = 'Google sign in failed: ${e.toString()}';
          });
        });
      }
    } finally {
      if (mounted) {

        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _isLoading = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Icon Image
              Image.asset(
                'assets/images/S.png',
                height: 100,
                width: 100,
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Email and password form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Login button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'Sign In',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Or divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Google sign in button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                    width: 24,
                  ),
                  label: const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA726),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      // Navigate to register screen
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const Register()));
                    },
                    child: const Text('Register Here'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}