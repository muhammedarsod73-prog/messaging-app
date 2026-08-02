import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final LocalStorageService _storage;

  late String _currentUserId;
  late String _pairCode;
  late String _partnerName;

  UserModel _currentUser = UserModel(
    id: 'user_a',
    pairCode: 'DUO2026',
    name: 'Partner 1',
    statusMessage: 'Connected on DuoChat',
    isOnline: true,
  );

  UserModel _partnerUser = UserModel(
    id: 'user_b',
    pairCode: 'DUO2026',
    name: 'Partner 2',
    statusMessage: 'Always connected ❤️',
    isOnline: true,
  );

  AuthProvider(this._storage) {
    _init();
  }

  void _init() {
    _currentUserId = _storage.getCurrentUserId();
    _pairCode = _storage.getPairCode();
    _partnerName = _storage.getPartnerName();

    _updateUserObjects();
  }

  String get currentUserId => _currentUserId;
  String get pairCode => _pairCode;
  String get partnerName => _partnerUser.name;
  UserModel get currentUser => _currentUser;
  UserModel get partnerUser => _partnerUser;

  bool get isUserA => _currentUserId == 'user_a';

  void _updateUserObjects() {
    if (_currentUserId == 'user_a') {
      _currentUser = UserModel(
        id: 'user_a',
        pairCode: _pairCode,
        name: 'Partner 1 (You)',
        statusMessage: 'Connected on DuoChat',
        isOnline: true,
      );
      _partnerUser = UserModel(
        id: 'user_b',
        pairCode: _pairCode,
        name: _partnerName.isNotEmpty ? _partnerName : 'Partner 2',
        statusMessage: 'Active on DuoChat',
        isOnline: true,
      );
    } else {
      _currentUser = UserModel(
        id: 'user_b',
        pairCode: _pairCode,
        name: 'Partner 2 (You)',
        statusMessage: 'Connected on DuoChat',
        isOnline: true,
      );
      _partnerUser = UserModel(
        id: 'user_a',
        pairCode: _pairCode,
        name: _partnerName.isNotEmpty ? _partnerName : 'Partner 1',
        statusMessage: 'Active on DuoChat',
        isOnline: true,
      );
    }
  }

  // Switch Role between User A and User B for 1-tap local dual testing
  Future<void> switchRole() async {
    _currentUserId = (_currentUserId == 'user_a') ? 'user_b' : 'user_a';
    await _storage.setCurrentUserId(_currentUserId);
    _updateUserObjects();
    notifyListeners();
  }

  Future<void> updatePairing(String newPairCode, String partnerName) async {
    _pairCode = newPairCode;
    _partnerName = partnerName;
    await _storage.setPairCode(newPairCode);
    await _storage.setPartnerName(partnerName);
    _updateUserObjects();
    notifyListeners();
  }

  void updatePartnerTyping(bool isTyping) {
    _partnerUser = _partnerUser.copyWith(isTyping: isTyping);
    notifyListeners();
  }
}
