import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data.dart';

class SettingsPage extends StatefulWidget {
  final UserData userData;
  final Function(UserData) onUserDataChanged;
  final String? lastSyncStatus;
  final DateTime? lastSyncTime;
  final VoidCallback? onSyncFromCloud;
  const SettingsPage({required this.userData, required this.onUserDataChanged, this.lastSyncStatus, this.lastSyncTime, this.onSyncFromCloud, super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? get user => FirebaseAuth.instance.currentUser;
  bool get isAnonymous => user?.isAnonymous ?? true;
  String? get email => user?.email;
  String? get displayName => user?.displayName;

  String get accountDisplay =>
    (displayName != null && displayName!.isNotEmpty)
      ? displayName!
      : (email ?? "알 수 없음");

  Future<void> _linkWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSimpleDialog('계정 연동 실패', '로그인이 되어 있지 않습니다. 잠시 후 다시 시도해 주세요.');
        return;
      }
      UserCredential userCredential;
      try {
        userCredential = await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        } else {
          _showSimpleDialog('계정 연동 실패', 'Google 계정 연동에 실패했습니다. (${e.message})');
          return;
        }
      }
      final cloudData = await downloadUserDataFromFirestore();
      if (cloudData != null) {
        widget.onUserDataChanged(cloudData);
        widget.onSyncFromCloud?.call();
        _showSimpleDialog('동기화 완료', '서버에서 데이터를 가져왔습니다.');
      } else {
        await uploadUserDataToFirestore(widget.userData);
        _showSimpleDialog('동기화 완료', '계정이 새로 등록되어 이제부터 서버로 동기화합니다.');
      }
      setState(() {});
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSimpleDialog('계정 연동 실패', '로그인이 되어 있지 않습니다. 잠시 후 다시 시도해 주세요.');
        return;
      }
      UserCredential userCredential;
      try {
        userCredential = await user.linkWithCredential(credential);
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
      final cloudData = await downloadUserDataFromFirestore();
      if (cloudData != null) {
        widget.onUserDataChanged(cloudData);
        widget.onSyncFromCloud?.call();
        _showSimpleDialog('동기화 완료', '서버에서 데이터를 가져왔습니다.');
      } else {
        await uploadUserDataToFirestore(widget.userData);
        _showSimpleDialog('동기화 완료', '계정이 새로 등록되어 이제부터 서버로 동기화합니다.');
      }
      setState(() {});
    } catch (e) {
      _showSimpleDialog('계정 연동 실패', '이메일 계정 연동 중 오류가 발생했습니다. ($e)');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃 확인'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('로그아웃')),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseAuth.instance.signOut();
    // Google 계정 선택 창이 다시 뜨도록 GoogleSignIn도 로그아웃
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
    // 로그아웃 후에만 익명 계정 자동 로그인
    await FirebaseAuth.instance.signInAnonymously();
    if (mounted) Navigator.pop(context);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('계정 연동 및 데이터 동기화'),
            subtitle: isAnonymous
                ? const Text('Google 또는 이메일 계정으로 연동하면, 다른 기기에서도 데이터를 동기화할 수 있습니다.')
                : Text('연동된 계정:  $accountDisplay'),
            onTap: isAnonymous
                ? () async {
                    final method = await showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('계정 연동 방법 선택'),
                        children: [
                          SimpleDialogOption(
                            child: const Text('Google로 연동'),
                            onPressed: () => Navigator.pop(context, 'google'),
                          ),
                          SimpleDialogOption(
                            child: const Text('이메일로 연동'),
                            onPressed: () => Navigator.pop(context, 'email'),
                          ),
                        ],
                      ),
                    );
                    if (method == 'google') await _linkWithGoogle();
                    if (method == 'email') await _linkWithEmail();
                  }
                : null,
            trailing: isAnonymous
                ? const Icon(Icons.link)
                : IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _logout,
                  ),
          ),
          const Divider(),
          ListTile(
            title: const Text('앱 데이터 동기화'),
            subtitle: const Text('데이터는 Firebase에 안전하게 백업되며, 계정 연동 시 다른 기기에서도 동기화됩니다.'),
          ),
          if (widget.lastSyncStatus != null || widget.lastSyncTime != null)
            ListTile(
              title: const Text('동기화 상태'),
              subtitle: Text('${widget.lastSyncStatus ?? ''}\n${widget.lastSyncTime != null ? widget.lastSyncTime.toString() : ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.sync),
                tooltip: '서버에서 최신 데이터로 동기화',
                onPressed: () async {
                  try {
                    final cloudData = await downloadUserDataFromFirestore();
                    if (cloudData != null) {
                      widget.onUserDataChanged(cloudData);
                      widget.onSyncFromCloud?.call();
                      _showSimpleDialog('동기화 완료', '서버에서 최신 데이터를 불러왔습니다.');
                    } else {
                      _showSimpleDialog('동기화 실패', '서버에 저장된 데이터가 없습니다.');
                    }
                  } catch (e) {
                    _showSimpleDialog('동기화 실패', '서버에서 데이터를 불러오지 못했습니다. ( [31m$e [0m)');
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
} 