import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/input_sanitizer.dart';
import '../../../shared/models/task_model.dart';
import '../../../core/services/fcm_server_service.dart';
import '../../../core/constants/app_strings.dart';

// ── Filter enum ───────────────────────────────────────────────

enum TaskFilter { all, myTasks, classTasks, overdue }

extension TaskFilterLabel on TaskFilter {
  String get label => switch (this) {
    TaskFilter.all        => 'All',
    TaskFilter.myTasks    => 'My Tasks',
    TaskFilter.classTasks => 'Class Tasks',
    TaskFilter.overdue    => 'Overdue',
  };
}

// ── State ─────────────────────────────────────────────────────

class TaskCrudState {
  final bool   isSaving;
  final bool   isDeleting;
  final String? error;
  final bool   success;

  const TaskCrudState({
    this.isSaving   = false,
    this.isDeleting = false,
    this.error,
    this.success    = false,
  });

  TaskCrudState copyWith({
    bool?   isSaving,
    bool?   isDeleting,
    String? error,
    bool?   success,
  }) =>
      TaskCrudState(
        isSaving:   isSaving   ?? this.isSaving,
        isDeleting: isDeleting ?? this.isDeleting,
        error:      error,
        success:    success    ?? this.success,
      );

  TaskCrudState reset() => const TaskCrudState();
}

// ── Task Stream Provider ──────────────────────────────────────

/// Merges class tasks + personal tasks into one deduplicated, date-sorted list.
/// For admin users, returns all tasks.
final tasksStreamProvider = StreamProvider<List<TaskModel>>((ref) {
  final userAsync = ref.watch(userModelProvider);
  final user      = userAsync.valueOrNull;
  if (user == null) return Stream.value([]);

  final db = FirebaseFirestore.instance;
  final ctrl = StreamController<List<TaskModel>>();
  final isAdmin = ref.read(isAdminProvider);

  List<TaskModel> classTasks    = [];
  List<TaskModel> personalTasks = [];
  Map<String, String> progressMap = {};
  
  bool classReady    = false;
  bool personalReady = false;
  bool progressReady = false;

  void emit() {
    if (!classReady || !personalReady || !progressReady) return;
    
    final finalTasks = <TaskModel>[];

    // Process class tasks: Apply local user status
    for (final ct in classTasks) {
      final userStatus = progressMap[ct.id];
      if (userStatus != null) {
        finalTasks.add(ct.copyWith(status: userStatus));
      } else {
        finalTasks.add(ct);
      }
    }

    // Process personal tasks
    for (final pt in personalTasks) {
      finalTasks.add(pt);
    }

    // Auto-delete tasks that ended > 1 week ago
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final displayTasks = <TaskModel>[];

    for (final task in finalTasks) {
      if (task.dueDate.isBefore(weekAgo)) {
        // Task has ended > 1 week ago. Attempt to delete if we have permission
        if (!task.isClassTask || isAdmin) {
          db.collection('tasks').doc(task.id).delete().catchError((_) {});
        }
      } else {
        displayTasks.add(task);
      }
    }

    // Sort by due date
    final sorted = displayTasks..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    ctrl.add(sorted);
  }

  // 1. Listen to User Progress (Real-time checkboxes)
  final subProg = db
      .collection('users')
      .doc(user.uid)
      .collection('task_progress')
      .snapshots()
      .listen((snap) {
        progressMap = {for (final d in snap.docs) d.id: d.get('status') as String};
        progressReady = true;
        emit();
      }, onError: (e) => ctrl.addError(e));

  // 2. Listen to Admin Tasks (Class tasks)
  final sub1 = db
      .collection('tasks')
      .where('isClassTask', isEqualTo: true)
      .snapshots()
      .listen((snap) {
        classTasks = snap.docs.map(TaskModel.fromFirestore).toList();
        classReady = true;
        emit();
      }, onError: (e) => ctrl.addError(e));

  // 3. Listen to Personal Tasks
  final sub2 = db
      .collection('tasks')
      .where('createdBy', isEqualTo: user.uid)
      .where('isClassTask', isEqualTo: false)
      .snapshots()
      .listen((snap) {
        personalTasks = snap.docs.map(TaskModel.fromFirestore).toList();
        personalReady = true;
        emit();
      }, onError: (e) => ctrl.addError(e));

  ref.onDispose(() {
    subProg.cancel();
    sub1.cancel();
    sub2.cancel();
    ctrl.close();
  });

  return ctrl.stream;
});

// ── Filter State ──────────────────────────────────────────────

final taskFilterProvider = StateProvider<TaskFilter>((_) => TaskFilter.all);

/// Derived provider: tasks filtered by [taskFilterProvider].
final filteredTasksProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  final allAsync = ref.watch(tasksStreamProvider);
  final filter   = ref.watch(taskFilterProvider);
  final uid      = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

  return allAsync.whenData((tasks) {
    return switch (filter) {
      TaskFilter.all        => tasks,
      TaskFilter.myTasks    => tasks.where((t) => t.createdBy == uid && !t.isClassTask).toList(),
      TaskFilter.classTasks => tasks.where((t) => t.isClassTask).toList(),
      TaskFilter.overdue    => tasks.where((t) => t.isOverdue).toList(),
    };
  });
});

/// Pending task count — used on home dashboard quick stats.
final pendingTaskCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(tasksStreamProvider).valueOrNull ?? [];
  return tasks.where((t) => t.status != 'done').length;
});

/// Overdue task count — used on home dashboard.
final overdueTaskCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(tasksStreamProvider).valueOrNull ?? [];
  return tasks.where((t) => t.isOverdue).length;
});

/// Next 3 pending tasks sorted by due date — for home dashboard preview.
final upcomingTasksPreviewProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksStreamProvider).valueOrNull ?? [];
  return tasks
      .where((t) => t.status != 'done' && !t.isOverdue)
      .take(3)
      .toList();
});

// ── Controller ────────────────────────────────────────────────

class TaskController extends StateNotifier<TaskCrudState> {
  TaskController() : super(const TaskCrudState());

  final _fs = FirestoreService.instance;

  // ── Create ──────────────────────────────────────────────────
  Future<void> createTask({
    required String   title,
    required String   description,
    required String   subject,
    required DateTime dueDate,
    required String   priority,
    required bool     isClassTask,
    required String   createdBy,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      final task = TaskModel(
        id:          '',
        title:       InputSanitizer.sanitizeTitle(title),
        description: InputSanitizer.sanitizeDescription(description),
        subject:     InputSanitizer.sanitizeText(subject),
        dueDate:     dueDate,
        priority:    priority,
        status:      'pending',
        createdBy:   createdBy,
        isClassTask: isClassTask,
        createdAt:   DateTime.now(),
      );
      final ref = await _fs.add('tasks', task.toFirestore());
      state = state.copyWith(isSaving: false, success: true);

      // Send FCM notification if it's a class task
      if (isClassTask) {
        await FcmServerService.sendNotification(
          title: 'New Class Task: ${task.title}',
          body:  'Due: ${task.dueDate.toLocal().toString().split(' ')[0]} - ${task.subject}',
          topic: AppStrings.fcmTopicTasks,
          data:  {'taskId': ref.id},
        );
      }
    } catch (e) {
      state = state.copyWith(
          isSaving: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Update ──────────────────────────────────────────────────
  Future<void> updateTask(TaskModel task) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _fs.update('tasks/${task.id}', task.toFirestore());
      state = state.copyWith(isSaving: false, success: true);

      // Send FCM notification if it's a class task
      if (task.isClassTask) {
        await FcmServerService.sendNotification(
          title: 'Class Task Updated: ${task.title}',
          body:  'Due: ${task.dueDate.toLocal().toString().split(' ')[0]} - ${task.subject}',
          topic: AppStrings.fcmTopicTasks,
          data:  {'taskId': task.id},
        );
      }
    } catch (e) {
      state = state.copyWith(
          isSaving: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Mark as done (toggle) ────────────────────────────────────
  Future<void> toggleStatus(TaskModel task) async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    final newStatus = task.status == 'done' ? 'pending' : 'done';

    if (task.isClassTask) {
      // For class tasks, we save the status in a user-specific subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('task_progress')
          .doc(task.id)
          .set({'status': newStatus, 'updatedAt': DateTime.now()});
    } else {
      // For personal tasks, update the document directly
      await _fs.update('tasks/${task.id}', {'status': newStatus});
    }
  }

  // ── Delete ───────────────────────────────────────────────────
  Future<void> deleteTask(String id) async {
    state = state.copyWith(isDeleting: true, error: null);
    try {
      await _fs.delete('tasks/$id');
      state = state.copyWith(isDeleting: false, success: true);
    } catch (e) {
      state = state.copyWith(
          isDeleting: false,
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void resetState() => state = state.reset();
}

final taskControllerProvider =
    StateNotifierProvider.autoDispose<TaskController, TaskCrudState>(
  (ref) => TaskController(),
);
