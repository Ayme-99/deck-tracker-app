import 'package:flutter/material.dart';


import 'package:deck_tracker_app/styles.dart';


import '../../services/auth_service.dart';


import '../../widgets/submit_on_enter.dart';


import '../home/home_screen.dart';


 


class RegisterScreen extends StatefulWidget {


  const RegisterScreen({super.key});


 


  @override


  State createState() => _RegisterScreenState();


}


 


class _RegisterScreenState extends State {


  final _formKey = GlobalKey();


  final _usernameController = TextEditingController();


  final _passwordController = TextEditingController();


  final _confirmPasswordController = TextEditingController();


  final _authService = AuthService();


 


  bool _isLoading = false;


  bool _obscurePassword = true;


  bool _obscureConfirmPassword = true;


  String? _errorMessage;


 


  Future _handleRegister() async {


    if (!_formKey.currentState!.validate()) return;


 


    setState(() {


      _isLoading = true;


      _errorMessage = null;


    });


 


    try {


      await _authService.register(


        _usernameController.text.trim(),


        _passwordController.text,


      );


 


      if (!mounted) return;


      Navigator.of(context).pushReplacement(


        MaterialPageRoute(builder: (_) => const HomeScreen()),


      );


    } catch (e) {


      setState(() {


        _errorMessage = e.toString().replaceFirst('Exception: ', '');


      });


    } finally {


      if (mounted) setState(() => _isLoading = false);


    }


  }


 


  @override


  void dispose() {


    _usernameController.dispose();


    _passwordController.dispose();


    _confirmPasswordController.dispose();


    super.dispose();


  }


 


  @override


  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(title: const Text('Crear cuenta')),


      body: SafeArea(


        child: Center(


          child: SingleChildScrollView(


            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingL),


            child: SubmitOnEnter(


              onSubmit: _handleRegister,


              enabled: !_isLoading,


              child: Form(


                key: _formKey,


                child: Column(


                  mainAxisSize: MainAxisSize.min,


                  crossAxisAlignment: CrossAxisAlignment.stretch,


                  children: [


                    TextFormField(


                      controller: _usernameController,


                      textInputAction: TextInputAction.next,


                      decoration: const InputDecoration(


                        labelText: 'Usuario',


                        border: OutlineInputBorder(),


                      ),


                      validator: (value) {


                        if (value == null || value.trim().isEmpty) {


                          return 'Introduce un usuario';


                        }


                        return null;


                      },


                    ),


                    const SizedBox(height: AppSizes.spacingM),


 


                    TextFormField(


                      controller: _passwordController,


                      obscureText: _obscurePassword,


                      textInputAction: TextInputAction.next,


                      decoration: InputDecoration(


                        labelText: 'Contraseña',


                        border: const OutlineInputBorder(),


                        suffixIcon: IconButton(


                          icon: Icon(


                            _obscurePassword ? Icons.visibility : Icons.visibility_off,


                          ),


                          onPressed: () {


                            setState(() => _obscurePassword = !_obscurePassword);


                          },


                        ),


                    ),


                    validator: (value) {


                      if (value == null || value.length < 6) {


                        return 'Mínimo 6 caracteres';


                      }


                      return null;


                    },


                  ),


                  const SizedBox(height: AppSizes.spacingM),


 


                  TextFormField(


                    controller: _confirmPasswordController,


                    obscureText: _obscureConfirmPassword,


                    textInputAction: TextInputAction.done,


                    decoration: InputDecoration(


                      labelText: 'Repite la contraseña',


                      border: const OutlineInputBorder(),


                      suffixIcon: IconButton(


                        icon: Icon(


                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,


                        ),


                        onPressed: () {


                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);


                        },


                      ),


                    ),


                    validator: (value) {


                      if (value == null || value.isEmpty) {


                        return 'Repite la contraseña';


                      }


                      if (value != _passwordController.text) {


                        return 'Las contraseñas no coinciden';


                      }


                      return null;


                    },


                  ),


                  const SizedBox(height: AppSizes.spacingL),


 


                  if (_errorMessage != null) ...[


                    Text(


                      _errorMessage!,


                      style: TextStyle(color: Theme.of(context).colorScheme.error),


                      textAlign: TextAlign.center,


                    ),


                    const SizedBox(height: AppSizes.spacingM),


                  ],


 


                  FilledButton(


                    onPressed: _isLoading ? null : _handleRegister,


                    child: _isLoading


                        ? const SizedBox(


                            height: 20,


                            width: 20,


                            child: CircularProgressIndicator(strokeWidth: 2),


                          )


                        : const Text('Crear cuenta'),


                  ),


                ],


              ),


              ),


            ),


          ),


        ),


      ),


    );


  }


}