import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_config.dart';
import '../../core/firebase/firebase_providers.dart';

class Account {
  const Account(this.email, this.verified, {this.uid});
  final String email;
  final bool verified;
  final String? uid;
}

abstract interface class AuthRepository {
  Stream<Account?> get changes;
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> verifyEmail();
  Future<void> reload();
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth);
  final FirebaseAuth auth;
  @override
  Stream<Account?> get changes => auth.userChanges().map(
    (user) => user == null
        ? null
        : Account(user.email ?? '', user.emailVerified, uid: user.uid),
  );
  @override
  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> register(String email, String password) async {
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      // Do not disclose whether an address is registered.
      if (error.code != 'user-not-found') rethrow;
    }
  }

  @override
  Future<void> verifyEmail() async {
    final user = auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-token-expired');
    await user.sendEmailVerification();
  }

  @override
  Future<void> reload() async {
    final user = auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-token-expired');
    await user.reload();
  }

  @override
  Future<void> signOut() => auth.signOut();
}

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final services = await ref.watch(firebaseStartupProvider.future);
  final config = ref.watch(firebaseConfigProvider);
  final auth = FirebaseAuth.instanceFor(app: services.app);
  if (config.mode == FirebaseMode.emulator) {
    await auth.useAuthEmulator(config.emulatorHost, 9099);
  }
  return FirebaseAuthRepository(auth);
});

final accountProvider = StreamProvider<Account?>((ref) async* {
  final repository = await ref.watch(authRepositoryProvider.future);
  yield* repository.changes;
});

String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'ทำรายการไม่สำเร็จ กรุณาลองอีกครั้ง';
  }
  return switch (error.code) {
    'invalid-email' => 'กรุณาตรวจสอบรูปแบบอีเมล',
    'user-token-expired' ||
    'invalid-user-token' => 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบอีกครั้ง',
    'weak-password' =>
      'รหัสผ่านไม่ตรงตามข้อกำหนด กรุณาใช้รหัสผ่านที่รัดกุมขึ้น',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
    'email-already-in-use' => 'สมัครไม่สำเร็จ ลองเข้าสู่ระบบหรือรีเซ็ตรหัสผ่าน',
    'network-request-failed' =>
      'เชื่อมต่อไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง',
    'too-many-requests' => 'ทำรายการบ่อยเกินไป กรุณารอสักครู่แล้วลองอีกครั้ง',
    'user-disabled' => 'บัญชีนี้ไม่สามารถใช้งานได้ กรุณาติดต่อผู้ดูแล',
    'operation-not-allowed' => 'ระบบบัญชียังไม่พร้อมใช้งาน กรุณาลองภายหลัง',
    _ => 'ทำรายการไม่สำเร็จ กรุณาลองอีกครั้ง',
  };
}
