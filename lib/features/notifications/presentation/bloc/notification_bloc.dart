// lib/features/notifications/presentation/bloc/notification_bloc.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/notification_model.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationEvent {
  final String? receiverId;
  final String? roomId;

  const LoadNotificationsEvent({this.receiverId, this.roomId});

  @override
  List<Object?> get props => [receiverId, roomId];
}

class SendNotificationEvent extends NotificationEvent {
  final NotificationModel notification;
  final File? imageFile;

  const SendNotificationEvent(this.notification, {this.imageFile});

  @override
  List<Object?> get props => [notification, imageFile];
}

class MarkNotificationAsReadEvent extends NotificationEvent {
  final String notificationId;
  const MarkNotificationAsReadEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class ResolveIssueEvent extends NotificationEvent {
  final String notificationId;
  const ResolveIssueEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

// ── States ────────────────────────────────────────────────────────────────
abstract class NotificationState extends Equatable {
  const NotificationState();
  
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}
class NotificationLoading extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  const NotificationsLoaded(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

class NotificationActionSuccess extends NotificationState {
  final String message;
  const NotificationActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Bloc ────────────────────────────────────────────────────────────────
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;

  NotificationBloc(this.repository) : super(NotificationInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<SendNotificationEvent>(_onSendNotification);
    on<MarkNotificationAsReadEvent>(_onMarkAsRead);
    on<ResolveIssueEvent>(_onResolveIssue);
  }

  Future<void> _onLoadNotifications(LoadNotificationsEvent event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    try {
      final notifications = await repository.getNotifications(
        receiverId: event.receiverId,
        roomId: event.roomId,
      );
      emit(NotificationsLoaded(notifications));
    } catch (e) {
      if (e is Failure) {
        emit(NotificationError(e.message));
      } else {
        emit(NotificationError(e.toString()));
      }
    }
  }

  Future<void> _onSendNotification(SendNotificationEvent event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    try {
      await repository.sendNotification(event.notification, imageFile: event.imageFile);
      emit(const NotificationActionSuccess('Gửi thành công!'));
    } catch (e) {
      if (e is Failure) {
        emit(NotificationError(e.message));
      } else {
        emit(NotificationError(e.toString()));
      }
    }
  }

  Future<void> _onMarkAsRead(MarkNotificationAsReadEvent event, Emitter<NotificationState> emit) async {
    try {
      await repository.markAsRead(event.notificationId);
      // We don't reload automatically here to prevent rebuild jumps, let the UI handle it or just silently update.
    } catch (_) {}
  }

  Future<void> _onResolveIssue(ResolveIssueEvent event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    try {
      await repository.resolveIssue(event.notificationId);
      emit(const NotificationActionSuccess('Đã chuyển trạng thái sự cố thành Đã giải quyết.'));
    } catch (e) {
      if (e is Failure) {
        emit(NotificationError(e.message));
      } else {
        emit(NotificationError(e.toString()));
      }
    }
  }
}
