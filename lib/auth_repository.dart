import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io';


enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthRepository with ChangeNotifier {
  final FirebaseAuth _auth;
  User? _user;
  Status _status = Status.Uninitialized;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  FirebaseStorage _storage = FirebaseStorage.instance;
  Set<WordPair> userData = <WordPair>{};
  AuthRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  Status get status => _status;

  User? get user => _user;

  bool get isAuthenticated => status == Status.Authenticated;

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      userData = await _getFavourites();
      notifyListeners();
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }


  Future<void> updateSavedSuggestions(WordPair pair, String first, String second ,{WordPair? remove = null})async {
    if(_status == Status.Authenticated){
      var tmp = _firebaseFirestore.collection('Users').doc(_user!.uid)
          .collection('Saved Suggestions')
          .doc(pair.toString());
      if(remove != null){
        await tmp.delete();
      }
      else {
        await tmp.set({'first': first, 'second': second});
      }
      userData = await _getFavourites();
    }

    notifyListeners();
  }


  Future<Set<WordPair>> _getFavourites() async {
    Set<WordPair> favourites = <WordPair>{};
    String first, second;
    await _firebaseFirestore.collection('Users')
        .doc(_user!.uid)
        .collection('Saved Suggestions')
        .get()
        .then((querySnapshot) {
      for (var result in querySnapshot.docs) {
        first = result.data().entries.first.value.toString();
        second = result.data().entries.last.value.toString();
        favourites.add(WordPair(first, second));
      }
    });
    return Future<Set<WordPair>>.value(favourites);
  }

  Set<WordPair> getData() {
    return userData;
  }


  Future<String> getUrl() async {
    return await _storage.ref('users').child(_user!.uid).getDownloadURL();
  }

  Future<void> updateImage(File file)async {
    await _storage
        .ref('users')
        .child(_user!.uid)
        .putFile(file);
    notifyListeners();
  }

}