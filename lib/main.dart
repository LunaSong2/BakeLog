import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:bakinglog/page_home.dart';
import 'package:bakinglog/data.dart';
import 'package:bakinglog/color_schemes.g.dart';
import 'package:bakinglog/typography.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // 익명 로그인은 앱 시작 시 하지 않음. (로그아웃 시에만)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
          textTheme: textTheme,
      ),
      darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme,
        textTheme: textTheme,
      ),
      themeMode: ThemeMode.light,
      home: const RecipeBuilder(),
    );
  }
}


class RecipeBuilder extends StatefulWidget {
  const RecipeBuilder({super.key});

  @override
  _RecipeBuilderState createState() => _RecipeBuilderState();
}

class _RecipeBuilderState extends State<RecipeBuilder> with WidgetsBindingObserver {
  UserData? userData;
  String appVersion = 'unknown';
  String lastSyncStatus = '';
  DateTime? lastSyncTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 로그 추가: 앱 시작 시 현재 로그인된 계정 정보 출력
    final user = FirebaseAuth.instance.currentUser;
    print('--- [앱 시작] FirebaseAuth.currentUser ---');
    print('user: ' + (user?.toString() ?? 'null'));
    print('isAnonymous: ' + (user?.isAnonymous.toString() ?? 'null'));
    print('email: ' + (user?.email ?? 'null'));
    print('displayName: ' + (user?.displayName ?? 'null'));
    _showOnboardingIfNeeded();
    _initAppVersion();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadRecipeData();
      }
    });
  }

  Future<void> _showOnboardingIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingShown = prefs.getBool('onboarding_shown') ?? false;
    if (!onboardingShown) {
      await Future.delayed(Duration.zero); // Ensure context is available
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('계정 연동 안내'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BakeLog의 데이터를 안전하게 백업하고 여러 기기에서 동기화하려면 계정 연동이 필요합니다.\n\n'
                '계정 연동 없이도 앱을 사용할 수 있지만, 기기 변경/앱 삭제 시 데이터가 사라질 수 있습니다.\n\n'
                '계정 연동은 언제든 설정에서 다시 할 수 있습니다.',
                textAlign: TextAlign.left,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'skip'),
              child: Text('나중에 할래요'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'link'),
              child: Text('계정 연동하기'),
            ),
          ],
        ),
      );
      prefs.setBool('onboarding_shown', true);
      if (result == 'link') {
        // 계정 연동 플로우로 이동 (구현 필요)
        if (mounted) await _showAccountLinkDialog();
      } else {
        // 익명 로그인 (이미 _signInAnonymouslyIfNeeded에서 처리)
      }
    }
  }

  Future<void> _showAccountLinkDialog() async {
    // 심플한 계정 연동 다이얼로그 (Google/Email)
    final method = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('계정 연동 방법 선택'),
        children: [
          SimpleDialogOption(
            child: Text('Google로 연동'),
            onPressed: () => Navigator.pop(context, 'google'),
          ),
          SimpleDialogOption(
            child: Text('이메일로 연동'),
            onPressed: () => Navigator.pop(context, 'email'),
          ),
          SimpleDialogOption(
            child: Text('취소'),
            onPressed: () => Navigator.pop(context, 'cancel'),
          ),
        ],
      ),
    );
    if (method == 'google') {
      // TODO: Google 연동 함수 호출
      if (mounted) await _linkWithGoogle();
    } else if (method == 'email') {
      // TODO: Email 연동 함수 호출
      if (mounted) await _linkWithEmail();
    }
  }

  Future<void> _linkWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential;
      try {
        // 기존 익명 계정에 연동 시도
        userCredential = await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // 이미 등록된 계정이면 해당 계정으로 로그인
          userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        } else {
          _showSimpleDialog('계정 연동 실패', 'Google 계정 연동에 실패했습니다. (${e.message})');
          return;
        }
      }
      // 로그인/연동 성공: 데이터 fetch 또는 업로드 분기
      final cloudData = await downloadUserDataFromFirestore();
      if (cloudData != null) {
        setState(() {
          userData = cloudData;
          lastSyncStatus = '계정에서 데이터 불러옴';
          lastSyncTime = DateTime.now();
        });
        _showSimpleDialog('동기화 완료', '계정에 저장된 데이터를 불러왔습니다.');
      } else {
        if (userData != null) {
          await uploadUserDataToFirestore(userData!);
          setState(() {
            lastSyncStatus = '계정에 데이터 업로드';
            lastSyncTime = DateTime.now();
          });
          _showSimpleDialog('동기화 완료', '현재 데이터를 계정에 업로드했습니다.');
        }
      }
    } catch (e) {
      _showSimpleDialog('계정 연동 실패', 'Google 계정 연동 중 오류가 발생했습니다. ($e)');
    }
  }

  Future<void> _linkWithEmail() async {
    String email = '';
    String password = '';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('이메일로 계정 연동'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '이메일'),
                onChanged: (v) => email = v,
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                onChanged: (v) => password = v,
              ),
              const SizedBox(height: 8),
              Text('이미 등록된 이메일이면 해당 계정의 데이터를 불러오고, 아니면 현재 데이터를 업로드합니다.', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('연동')),
          ],
        );
      },
    );
    if (result != true || email.isEmpty || password.isEmpty) return;
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        } else if (e.code == 'wrong-password' || e.code == 'user-not-found') {
          _showSimpleDialog('계정 연동 실패', '이메일 또는 비밀번호가 올바르지 않습니다.');
          return;
        } else {
          _showSimpleDialog('계정 연동 실패', '이메일 연동에 실패했습니다. (${e.message})');
          return;
        }
      }
      // 로그인/연동 성공: 데이터 fetch 또는 업로드 분기
      final cloudData = await downloadUserDataFromFirestore();
      if (cloudData != null) {
        setState(() {
          userData = cloudData;
          lastSyncStatus = '계정에서 데이터 불러옴';
          lastSyncTime = DateTime.now();
        });
        _showSimpleDialog('동기화 완료', '계정에 저장된 데이터를 불러왔습니다.');
      } else {
        if (userData != null) {
          await uploadUserDataToFirestore(userData!);
          setState(() {
            lastSyncStatus = '계정에 데이터 업로드';
            lastSyncTime = DateTime.now();
          });
          _showSimpleDialog('동기화 완료', '현재 데이터를 계정에 업로드했습니다.');
        }
      }
    } catch (e) {
      _showSimpleDialog('계정 연동 실패', '이메일 계정 연동 중 오류가 발생했습니다. ($e)');
    }
  }

  Future<void> _initAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
    });
    await loadRecipeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      saveRecipeData();
    }
  }

  Future<void> loadRecipeDataForTest() async {
    String jsonString = await rootBundle.loadString('assets/data.json');
    Map<String, dynamic> jsonData = jsonDecode(jsonString);
    setState(() {
      userData = UserData.fromJson(jsonData);
      if (userData != null) userData!.appVersion = appVersion;
    });
    print('Recipe from asset path loaded successfully');
  }

  Future<void> loadRecipeData() async {
    try {
      // 1. Firestore에서 먼저 시도
      final cloudData = await downloadUserDataFromFirestore();
      if (cloudData != null) {
        setState(() {
          userData = cloudData;
          userData!.appVersion = appVersion;
          lastSyncStatus = '클라우드에서 동기화 성공';
          lastSyncTime = DateTime.now();
        });
        print('Recipe loaded from Firestore');
        return;
      }
    } catch (e) {
      print('Error loading from Firestore: $e');
      setState(() {
        lastSyncStatus = '클라우드 동기화 실패';
        lastSyncTime = DateTime.now();
      });
    }
    // 2. Firestore 실패 시 로컬에서 시도
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data.json');
      String jsonString = await file.readAsString();
      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      setState(() {
        userData = UserData.fromJson(jsonData);
        if (userData != null) userData!.appVersion = appVersion;
        lastSyncStatus = '로컬에서 불러옴';
        lastSyncTime = DateTime.now();
      });
      print('Recipe loaded from local');
    } catch (e) {
      print('Error loading user data: $e, load test data instead');
      setState(() {
        lastSyncStatus = '로컬 동기화 실패';
        lastSyncTime = DateTime.now();
      });
      await loadRecipeDataForTest();
    }
  }

  // 계정 연동 후 서버에서 데이터 가져올 때도 동기화 상태 갱신
  void updateSyncStatusFromCloud() {
    setState(() {
      lastSyncStatus = '클라우드에서 동기화 성공';
      lastSyncTime = DateTime.now();
    });
  }

  Future<void> saveRecipeData() async {
    if (userData != null) {
      userData!.appVersion = appVersion;
      String jsonString = jsonEncode(userData!.toJson());
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/data.json');
      await file.writeAsString(jsonString);
      print ('Recipe saved successfully');

      final externalDirectory = await getExternalStorageDirectory();
      final externalFile = File('${externalDirectory!.path}/data.json');
      await externalFile.writeAsString(jsonString);
      print ('Recipe saved to external storage successfully');
      // Firestore에도 업로드
      try {
        if (FirebaseAuth.instance.currentUser != null) {
          await uploadUserDataToFirestore(userData!);
          setState(() {
            lastSyncStatus = '클라우드에 동기화 성공';
            lastSyncTime = DateTime.now();
          });
        } else {
          print('No user is currently signed in. Skipping Firestore upload.');
        }
      } catch (e) {
        setState(() {
          lastSyncStatus = '클라우드 동기화 실패';
          lastSyncTime = DateTime.now();
        });
        print('Error uploading to Firestore: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userData != null
          ? RecipeList(
              userData: userData!,
              lastSyncStatus: lastSyncStatus,
              lastSyncTime: lastSyncTime,
              onSave: saveRecipeData,
              onSyncFromCloud: updateSyncStatusFromCloud,
            )
          : const Center(child: CircularProgressIndicator()), // 데이터 로딩 중 표시
    );
  }

/*  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Baking Log'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: loadRecipeDataForTest,
              child: Text('Load Test Recipe'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: loadRecipeData,
              child: Text('Load Recipe'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: saveRecipeData,
              child: Text('Save Recipe'),
            ),
          ],
        ),
      ),
    );
  }*/

  Future<void> _showSimpleDialog(String title, String content) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('확인'))],
      ),
    );
  }
}