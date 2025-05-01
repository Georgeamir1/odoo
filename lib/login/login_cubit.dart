import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../networking/odoo_service.dart';
import 'login_states.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());
  final odooService = OdooRpcService();

  static LoginCubit get(context) => BlocProvider.of(context);

  void loginUser(String username, String password) async {
    emit(LoginLoading());

    try {
      int? partnerId = await odooService.login(username, password);
      if (partnerId != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setInt('partner_id', partnerId);

        emit(LoginSuccess("Logged in! Partner ID: $partnerId"));
      } else {
        emit(LoginError("Invalid credentials or partner ID not found"));
      }
    } catch (e) {
      emit(LoginError("An error occurred: $e"));
    }
  }

/*
  int getCurrentWeekNumber() {
    final now = DateTime.now();

    final startOfYear = DateTime(now.year, 1, 1);

    final difference = now.difference(startOfYear).inDays;

    final weekNumber = ((difference + startOfYear.weekday - 1) / 7).floor() + 1;

    return weekNumber;
  }
*/

// Usage example:
}

/*
class WeekNumberDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weekNumber = LoginCubit.get(context).getCurrentWeekNumber();
    int currentyear = DateTime.now().year;
    String currentyearstring = currentyear.toString();
    return Center(
      child: Text(
        'PS $weekNumber ${currentyearstring.substring(2)}',
        style: TextStyle(
            fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500),
      ),
    );
  }
}
*/
