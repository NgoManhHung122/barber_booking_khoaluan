import 'package:shared_preferences/shared_preferences.dart';

class SharedpreferenceHelper {
  // Key thống nhất cho toàn bộ app
  static const String userIdKey = "USERKEY";
  static const String userNameKey = "USERNAMEKEY";
  static const String userEmailKey = "USEREMAILKEY";
  static const String userAvatarKey = "USERAVATARKEY";
  static const String userWalletKey = "USERWALLETKEY";

  Future<bool> saveUserWallet(String amount) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userWalletKey, amount);
  }

  Future<String?> getUserWallet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userWalletKey);
  }

  // Lưu dữ liệu
  Future<bool> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userIdKey, userId);
  }

  Future<bool> saveUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userNameKey, userName);
  }

  Future<bool> saveUserEmail(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userEmailKey, userEmail);
  }

  Future<bool> saveUserAvatar(String avatarUrl) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userAvatarKey, avatarUrl);
  }

  // Lấy dữ liệu
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNameKey);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailKey);
  }

  Future<String?> getUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userAvatarKey);
  }

  // Stream theo dõi thay đổi avatar
  Stream<String?> getUserAvatarStream() {
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(userAvatarKey);
    });
  }

  // Xử lý logout
  Future<bool> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdKey);
    await prefs.remove(userNameKey);
    await prefs.remove(userEmailKey);
    await prefs.remove(userAvatarKey); // Xóa luôn avatar nếu cần
    await prefs.remove(userWalletKey);
    return true;
  }
}
