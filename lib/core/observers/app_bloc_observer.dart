// lib/core/observers/app_bloc_observer.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    // ignore: avoid_print
    print('🟢 BLoC Created: ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // ignore: avoid_print
    print('🔄 ${bloc.runtimeType}: ${change.currentState.runtimeType} → ${change.nextState.runtimeType}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    // ignore: avoid_print
    print('❌ ${bloc.runtimeType} Error: $error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    // ignore: avoid_print
    print('🔴 BLoC Closed: ${bloc.runtimeType}');
  }
}
