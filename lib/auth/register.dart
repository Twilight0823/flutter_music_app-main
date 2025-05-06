import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:music_app/auth/login.dart';
import 'package:music_app/services/auth_service.dart'; // Import AuthService

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => RegisterState();
}

class RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController(); // Added for birthdate validation
  
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _birthdateError; // Added to track birthdate validation error
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Use AuthService instead of direct Firebase references
  final AuthService _authService = AuthService();
  
  final List<String> _genders = ['Male', 'Female', 'Prefer not to say'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _birthdateController.dispose(); // Dispose the birthdate controller
    super.dispose();
  }

  // Calculate age based on birthdate
  void _calculateAge() {
    if (_selectedDate != null) {
      final DateTime now = DateTime.now();
      int age = now.year - _selectedDate!.year;
      
      // Adjust age if birthday hasn't occurred yet this year
      if (now.month < _selectedDate!.month || 
          (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
        age--;
      }
      
      setState(() {
        _ageController.text = age.toString();
        _birthdateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
        _birthdateError = null; // Clear any validation error
      });
    }
  }

  // Date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
      _selectedDate = picked;
        _calculateAge();
      });
    });
    }
  }

  // Validate birthdate field
  String? _validateBirthdate(String? value) {
    if (_selectedDate == null) {
      return 'Please select your birth date';
    }
    return null;
  }

  // Register with email and password using AuthService
  Future<void> _register() async {
    // Validate birthdate explicitly

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
      _birthdateError = _validateBirthdate(null);
      });
    });
    
    if (_formKey.currentState!.validate() && _birthdateError == null) {
      if (_selectedGender == null) {

        WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
      _errorMessage = 'Please select a gender';_isLoading = true;
      _errorMessage = '';
      });
    });
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
      _isLoading = true;
      _errorMessage = '';
      });
    });

      try {
        // Create user data map
        final Map<String, dynamic> userData = {
          'gender': _selectedGender,
          'birthdate': _selectedDate,
          'age': int.parse(_ageController.text),
        };

        // Use AuthService to create user with email and password
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          userData,
        );
        
        if (!mounted) return;
        
        // Show success message before navigation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to login screen
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()));
      } catch (e) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
          _errorMessage = e.toString();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App logo or icon
              Icon(
                Icons.person_add_outlined,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Create New Account',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please fill in the form to register',
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
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              
              // Registration form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email
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
                    
                    // Password
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
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Gender selection
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.people_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select Gender';
                        }
                        return null;
                      },
                      items: _genders.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                        _selectedGender = newValue;
                        });
                      });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Birth date 
                    TextFormField(
                      controller: _birthdateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Birth Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: const OutlineInputBorder(),
                        errorText: _birthdateError,
                        hintText: 'Select date',
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      onTap: () => _selectDate(context),
                      validator: _validateBirthdate,
                    ),
                    const SizedBox(height: 16),
                    
                    // Age (auto-calculated and read-only)
                    TextFormField(
                      controller: _ageController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        hintText: 'Auto-calculated from birth date',
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Register button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'Register',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      // Navigate to login screen
                      Navigator.pushReplacement
                      (context, 
                      MaterialPageRoute(builder: 
                      (context) => const Login()));
                    },
                    child: const Text('Login Here'),
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