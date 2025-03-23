import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences package
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:odoo/login/login_cubit.dart';
import 'package:odoo/login/login_states.dart';
import '../home/home_ui.dart';
import '../localization.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool? isArabic; // To store the current language status

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Determine if the current locale is Arabic.
    isArabic = Localizations.localeOf(context).languageCode == 'ar';
    // Save the preference (this will be called when dependencies change).
    _saveLanguagePreference(isArabic!);
  }

  // Helper function to save language preference in SharedPreferences
  Future<void> _saveLanguagePreference(bool isArabic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isArabic', isArabic);
  }

  @override
  Widget build(BuildContext context) {
    // Note: You can also retrieve and update isArabic here if needed.
    final currentIsArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: BlocProvider(
        create: (context) => LoginCubit(),
        child: BlocConsumer<LoginCubit, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HomePage(
                    changeLanguage: (String languageCode) {
                      // You could also update and save the language preference here if needed.
                      Localizations.localeOf(context).languageCode;
                    },
                  ),
                ),
              );
            } else if (state is LoginError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return Directionality(
              textDirection:
                  currentIsArabic ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                color: const Color(0xFFFFFFFF),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Image.asset(
                          "assets/images/logo.png",
                          height: 300,
                        ),
                        // Login Card
                        Card(
                          color: const Color(0xFFF7F7F7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 12,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      labelText:
                                          AppLocalizations.of(context).username,
                                      labelStyle: const TextStyle(
                                          color: Color(0xFF333333)),
                                      prefixIcon: const Icon(
                                          Icons.person_outline,
                                          color: Color(0xFF333333)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF1E88E5)),
                                      ),
                                    ),
                                    textAlign: currentIsArabic
                                        ? TextAlign.right
                                        : TextAlign.left,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppLocalizations.of(context)
                                            .usernameRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText:
                                          AppLocalizations.of(context).password,
                                      labelStyle: const TextStyle(
                                          color: Color(0xFF333333)),
                                      prefixIcon: const Icon(Icons.lock_outline,
                                          color: Color(0xFF333333)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: const Color(0xFF333333),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF1E88E5)),
                                      ),
                                    ),
                                    textAlign: currentIsArabic
                                        ? TextAlign.right
                                        : TextAlign.left,
                                    obscureText: _obscurePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppLocalizations.of(context)
                                            .passwordRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        backgroundColor:
                                            const Color(0xFF714B67),
                                      ),
                                      onPressed: state is LoginLoading
                                          ? null
                                          : () {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                context
                                                    .read<LoginCubit>()
                                                    .loginUser(
                                                      _usernameController.text,
                                                      _passwordController.text,
                                                    );
                                              }
                                            },
                                      child: state is LoginLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              AppLocalizations.of(context)
                                                  .login,
                                              style: GoogleFonts.getFont(
                                                currentIsArabic
                                                    ? 'Cairo'
                                                    : 'Lato',
                                                textStyle: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Language Switcher
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                context.read<LocaleCubit>().switchToEnglish();
                                _saveLanguagePreference(
                                    false); // Save English preference
                              },
                              child: Text(
                                'English',
                                style: TextStyle(
                                  color: Localizations.localeOf(context)
                                              .languageCode ==
                                          'en'
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<LocaleCubit>().switchToArabic();
                                _saveLanguagePreference(
                                    true); // Save Arabic preference
                              },
                              child: Text(
                                'العربية',
                                style: TextStyle(
                                  color: Localizations.localeOf(context)
                                              .languageCode ==
                                          'ar'
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Add this LocaleCubit to your app's bloc layer
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('en'));

  void switchToEnglish() => emit(const Locale('en'));
  void switchToArabic() => emit(const Locale('ar'));
}
