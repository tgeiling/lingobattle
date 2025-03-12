import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:provider/provider.dart';

import 'provider.dart';

class SocketService with ChangeNotifier {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late IO.Socket _socket;
  bool _isConnected = false;
  bool _isInitialized = false; // Prevents multiple initializations

  SocketService._internal();

  void initialize(BuildContext context) {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    if (profileProvider.username.isNotEmpty && !_isInitialized) {
      _isInitialized = true;
      _initializeSocket();
    }
  }

  void _initializeSocket() {
    print("Initializing socket connection...");
    _socket = IO.io('http://34.159.152.1:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.onConnect((_) {
      print('Connected to WebSocket server');
      _isConnected = true;
      notifyListeners();
    });

    _socket.onDisconnect((_) {
      print('Disconnected from WebSocket server');
      _isConnected = false;
      notifyListeners();
    });

    _socket.onConnectError((data) {
      print('Connection Error: $data');
    });

    _socket.onError((data) {
      print('Socket Error: $data');
    });

    _socket.onReconnect((_) {
      print('Reconnected to WebSocket server');
      _isConnected = true;
      notifyListeners();
    });

    _socket.onReconnectAttempt((_) {
      print('Reconnecting to WebSocket...');
    });

    _socket.connect();
  }

  IO.Socket get socket => _socket;
  bool get isConnected => _isConnected;

  void disconnectSocket() {
    if (_isInitialized) {
      _socket.disconnect();
      _isConnected = false;
      _isInitialized = false;
      print('Socket manually disconnected.');
      notifyListeners();
    }
  }

  void joinQueue(String username, String language) {
    _socket.emit('joinQueue', {'username': username, 'language': language});
    print('Emitted joinQueue for $username');
  }

  void joinFriendMatch(
      String username, String language, String friendUsername) {
    _socket.emit('joinFriendMatch', {
      'username': username,
      'language': language,
      'friend': friendUsername,
    });
    print('Emitted joinFriendMatch for $username and $friendUsername');
  }

  void leaveQueue() {
    _socket.emit('leaveQueue');
    print('Emitted leaveQueue');
  }

  void sendBattleRequest(String senderUsername, String receiverUsername) {
    _socket.emit('sendBattleRequest', {
      'sender': senderUsername,
      'receiver': receiverUsername,
    });
    print(
        'Emitted sendBattleRequest from $senderUsername to $receiverUsername');
  }

  void acceptBattleRequest(String username, String opponentUsername) {
    _socket.emit('acceptBattleRequest', {
      'username': username,
      'opponent': opponentUsername,
    });
    print('Emitted acceptBattleRequest for $username vs $opponentUsername');
  }

  void rejectBattleRequest(String username, String opponentUsername) {
    _socket.emit('rejectBattleRequest', {
      'username': username,
      'opponent': opponentUsername,
    });
    print('Emitted rejectBattleRequest for $username vs $opponentUsername');
  }

  void submitAnswer(
      String matchId, String username, int questionIndex, String status) {
    _socket.emit('submitAnswer', {
      'matchId': matchId,
      'username': username,
      'questionIndex': questionIndex,
      'status': status,
    });
    print('Emitted submitAnswer for match $matchId by $username');
  }

  void submitResults(String matchId, String username, int correctAnswers,
      String language, List<String> questions) {
    _socket.emit('submitResults', {
      'matchId': matchId,
      'username': username,
      'correctAnswers': correctAnswers,
      'language': language,
      'questions': questions,
    });
    print('Emitted submitResults for match $matchId by $username');
  }

  void emitPlayerLeft(String matchId, String username) {
    _socket.emit('playerLeft', {
      'matchId': matchId,
      'username': username,
    });
    print("Emitted playerLeft event for match $matchId, player: $username");
  }

  //[Turn on] Area
  void activateProgressUpdate(Function(Map<String, dynamic>) onProgressUpdate) {
    print("[Listener Added] Listening for 'progressUpdate'");
    _socket.on('progressUpdate', (data) => onProgressUpdate(data));
  }

  void activateBattleEnded(Function(Map<String, dynamic>) onBattleEnded) {
    print("[Listener Added] Listening for 'battleEnded'");
    _socket.on('battleEnded', (data) => onBattleEnded(data));
  }

  //[Turn off] Area
  void removeAllListeners() {
    print("Removing all listeners...");
    _socket.off('connect');
    _socket.off('disconnect');
    _socket.off('battleStart');
    _socket.off('matchFound');
    _socket.off('progressUpdate');
    _socket.off('battleEnded');
    print("All listeners removed.");
  }
}
