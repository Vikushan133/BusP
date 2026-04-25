import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class FirebaseService {
  static final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static auth.FirebaseAuth get authService => _auth;
  static FirebaseFirestore get firestore => _firestore;
  static FirebaseStorage get storage => _storage;

  static auth.User? get currentUser => _auth.currentUser;

  static Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  static Future<auth.UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<auth.UserCredential> register(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    auth.UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    auth.User user = credential.user!;
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return credential;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<AppUser?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  static Future<void> updateUser(
    String uid,
    String firstName,
    String lastName,
  ) async {
    await _firestore.collection('users').doc(uid).update({
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  static Future<void> addProblem(Map<String, dynamic> problemData) async {
    await _firestore.collection('problems').add(problemData);
  }

  static Future<void> addLostItem(Map<String, dynamic> itemData) async {
    await _firestore.collection('lost_items').add(itemData);
  }

  static Future<void> addFoundItem(Map<String, dynamic> itemData) async {
    await _firestore.collection('found_items').add(itemData);
  }

  static Future<List<Map<String, dynamic>>> getUserProblems(String userId) async {
    QuerySnapshot query = await _firestore
        .collection('problems')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getUserLostItems(String userId) async {
    QuerySnapshot query = await _firestore
        .collection('lost_items')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getUserFoundItems(String userId) async {
    QuerySnapshot query = await _firestore
        .collection('found_items')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllFoundItems() async {
    QuerySnapshot query = await _firestore
        .collection('found_items')
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllLostItems() async {
    QuerySnapshot query = await _firestore
        .collection('lost_items')
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<String> uploadImage(String path, String fileName) async {
    Reference ref = _storage.ref().child('images').child(fileName);
    UploadTask task = ref.putFile(File(path));
    TaskSnapshot snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }
}