import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../networking/odoo_service.dart';
import 'login_states.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());
  final odooService = OdooRpcService();

  static LoginCubit get(context) => BlocProvider.of(context);

  void loginUser(String username, String password) async {
    emit(LoginLoading()); // Emit loading state

    try {
      bool success = (await odooService.login(username, password));
      if (success) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        emit(LoginSuccess("Logged in successfully!")); // Emit success state
      } else {
        emit(LoginError("Invalid username or password")); // Emit error state
      }
    } catch (e) {
      emit(LoginError("An error occurred: $e")); // Emit error state
    }
  }
}
