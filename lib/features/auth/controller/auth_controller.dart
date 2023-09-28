import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/apis/auth_api.dart';
import 'package:twitter_clone/apis/user_api.dart';
import 'package:twitter_clone/features/view/home_view.dart';
import 'package:twitter_clone/features/auth/view/login_view.dart';
import 'package:twitter_clone/models/user_model.dart';
import '../../../core/core.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(
      authAPI: ref.watch(authProvider), userApI: ref.watch(userProvider));
});

final userDetailsProvider = FutureProvider.family((ref, String uid) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.getUserData(uid);
});

final currentUserDetailsProvider = FutureProvider((ref) {
  final currentUserId = ref.watch(currentAccountProvider).value!.$id;
  final userDetails = ref.watch(userDetailsProvider(currentUserId));
  return userDetails.value;
});

final currentAccountProvider = FutureProvider((ref) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.currentUser();
});

class AuthController extends StateNotifier<bool> {
  final AuthAPI _authAPI;
  final UserApI _userApI;
  AuthController({required AuthAPI authAPI, required UserApI userApI})
      : _authAPI = authAPI,
        _userApI = userApI,
        super(false);

  Future<User?> currentUser() => _authAPI.currentUserAccount();

  void signUP(
      {required String email,
      required String password,
      required BuildContext context}) async {
    state = true;

    final res = await _authAPI.signUp(email: email, password: password);
    state = false;

    res.fold((l) => showSnackBar(context, l.message), (r) async {
      UserModel userModel = UserModel(
          email: email,
          uid: r.$id,
          bannerPic: '',
          profilePic: '',
          bio: '',
          isTwitterBlue: false,
          followers: const [],
          following: const [],
          name: getNameFromEmail(email));
      final res2 = await _userApI.saveUserData(userModel);
      res2.fold((l) => showSnackBar(context, l.message), (r) {
        showSnackBar(context, 'Account created successfully. Please login');
        Navigator.push(
          context,
          LoginView.route(),
        );
      });
    });
  }

  void login(
      {required String email,
      required String password,
      required BuildContext context}) async {
    state = true;

    final res = await _authAPI.login(email: email, password: password);
    state = false;

    res.fold((l) => showSnackBar(context, l.message), (r) {
      showSnackBar(context, 'Login successful');
      Navigator.push(
        context,
        HomeView.route(),
      );
    });
  }

  Future<UserModel> getUserData(String uid) async {
    final document = await _userApI.getUserData(uid);
    final updateUser = UserModel.fromMap(document.data);
    return updateUser;
  }
}
