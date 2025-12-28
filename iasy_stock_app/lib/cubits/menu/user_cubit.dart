import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/user_model.dart';
import '../../services/menu/user_service.dart';

sealed class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<UserModel> users;
  final int currentPage;
  final bool hasMoreData;
  final bool isLoadingMore;

  UserLoaded(
    this.users, {
    this.currentPage = 0,
    this.hasMoreData = true,
    this.isLoadingMore = false,
  });

  UserLoaded copyWith({
    List<UserModel>? users,
    int? currentPage,
    bool? hasMoreData,
    bool? isLoadingMore,
  }) {
    return UserLoaded(
      users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SingleUserLoaded extends UserState {
  final UserModel user;

  SingleUserLoaded(this.user);
}

class UserCubit extends Cubit<UserState> {
  final UserService userService;
  List<UserModel> _users = [];
  int _currentPage = 0;
  static const int _pageSize = 20;

  UserCubit(this.userService) : super(UserInitial());

  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh || state is UserInitial) {
      _currentPage = 0;
      _users.clear();
      emit(UserLoading());
    }

    try {
      final newUsers =
          await userService.getAll(page: _currentPage, size: _pageSize);

      if (refresh || _users.isEmpty) {
        _users = newUsers;
      } else {
        _users.addAll(newUsers);
      }

      final hasMoreData = newUsers.length >= _pageSize;
      emit(UserLoaded(
        List.unmodifiable(_users),
        currentPage: _currentPage,
        hasMoreData: hasMoreData,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (!isClosed) {
        emit(UserInitial());
      }
      rethrow;
    }
  }

  Future<void> loadMoreUsers() async {
    final currentState = state;
    if (currentState is UserLoaded &&
        !currentState.isLoadingMore &&
        currentState.hasMoreData) {
      emit(currentState.copyWith(isLoadingMore: true));

      try {
        _currentPage++;
        final newUsers =
            await userService.getAll(page: _currentPage, size: _pageSize);

        _users.addAll(newUsers);
        final hasMoreData = newUsers.length >= _pageSize;

        emit(UserLoaded(
          List.unmodifiable(_users),
          currentPage: _currentPage,
          hasMoreData: hasMoreData,
          isLoadingMore: false,
        ));
      } catch (e) {
        _currentPage--;
        if (!isClosed) {
          emit(currentState.copyWith(isLoadingMore: false));
        }
        rethrow;
      }
    }
  }

  Future<void> createUser(UserModel user) async {
    await userService.create(user);
  }

  Future<void> updateUser(UserModel user) async {
    await userService.update(user.id!, user);
  }

  Future<void> deleteUser(int id) async {
    await userService.delete(id);
  }

  Future<void> getUserById(int id) async {
    emit(UserLoading());
    try {
      final user = await userService.getById(id);
      emit(SingleUserLoaded(user));
    } catch (e) {
      if (!isClosed) {
        emit(UserInitial());
      }
      rethrow;
    }
  }

  Future<void> findByUsername(String username) async {
    emit(UserLoading());
    try {
      final user = await userService.findByUsername(username);
      emit(SingleUserLoaded(user));
    } catch (e) {
      if (!isClosed) {
        emit(UserInitial());
      }
      rethrow;
    }
  }

  Future<void> findByEmail(String email) async {
    emit(UserLoading());
    try {
      final user = await userService.findByEmail(email);
      emit(SingleUserLoaded(user));
    } catch (e) {
      if (!isClosed) {
        emit(UserInitial());
      }
      rethrow;
    }
  }

  Future<void> findByRole(String role, {int page = 0, int size = 10}) async {
    emit(UserLoading());
    try {
      final result = await userService.findByRole(role, page: page, size: size);
      emit(UserLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(UserInitial());
      }
      rethrow;
    }
  }

  void resetState() {
    emit(UserInitial());
  }
}
