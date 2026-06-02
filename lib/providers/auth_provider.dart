import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../config.dart';

class AuthState {
  final GoogleSignInAccount? user;
  final http.Client? client;
  final bool isLoading;
  final String? errorMessage;
  final bool isOfflineMode;

  AuthState({
    this.user,
    this.client,
    this.isLoading = false,
    this.errorMessage,
    this.isOfflineMode = false,
  });

  AuthState copyWith({
    GoogleSignInAccount? user,
    http.Client? client,
    bool? isLoading,
    String? errorMessage,
    bool? isOfflineMode,
    bool clearUser = false,
    bool clearClient = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      client: clearClient ? null : (client ?? this.client),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final GoogleSignIn _googleSignIn;

  AuthNotifier()
      : _googleSignIn = GoogleSignIn(
          clientId: AppConfig.googleClientId,
          scopes: [
            drive.DriveApi.driveFileScope,
          ],
        ),
        super(AuthState()) {
    // Listen for authentication changes dynamically
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account != null) {
        final hasScope = await _googleSignIn.canAccessScopes([drive.DriveApi.driveFileScope]);
        if (hasScope) {
          final client = await _googleSignIn.authenticatedClient();
          state = AuthState(user: account, client: client, isLoading: false, isOfflineMode: false);
        } else {
          // Required scope is missing; do not provide the client yet
          state = AuthState(user: account, client: null, isLoading: false, isOfflineMode: false);
        }
      } else {
        state = state.copyWith(clearUser: true, clearClient: true, isLoading: false);
      }
    }, onError: (err) {
      state = state.copyWith(errorMessage: 'Auth listener error: $err', isLoading: false);
    });

    // Attempt silent sign-in on initialization
    silentSignIn();
  }

  void enterOfflineMode() {
    state = state.copyWith(isOfflineMode: true, errorMessage: null);
  }

  void exitOfflineMode() {
    state = state.copyWith(isOfflineMode: false);
  }

  Future<void> silentSignIn() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        final hasScope = await _googleSignIn.canAccessScopes([drive.DriveApi.driveFileScope]);
        if (!hasScope) {
          // If silent sign-in succeeded but lacks scope, log out to keep state consistent and clean
          await _googleSignIn.signOut();
        }
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Silent Sign-In failed: $e',
      );
    }
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final hasScope = await _googleSignIn.canAccessScopes([drive.DriveApi.driveFileScope]);
        if (!hasScope) {
          // Request scopes explicitly if missing after signing in
          final success = await _googleSignIn.requestScopes([drive.DriveApi.driveFileScope]);
          if (!success) {
            // Cancel sign-in if the user denied scope authorization
            await _googleSignIn.signOut();
          }
        }
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign-In failed: $e',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _googleSignIn.signOut();
      state = state.copyWith(clearUser: true, clearClient: true, isOfflineMode: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign-Out failed: $e',
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
