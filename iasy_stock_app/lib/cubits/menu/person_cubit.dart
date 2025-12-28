import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/person_model.dart';
import '../../services/menu/person_service.dart';

sealed class PersonState {}

class PersonInitial extends PersonState {}

class PersonLoading extends PersonState {}

class PersonLoaded extends PersonState {
  final List<PersonModel> persons;
  final int currentPage;
  final bool hasMoreData;
  final bool isLoadingMore;

  PersonLoaded(
    this.persons, {
    this.currentPage = 0,
    this.hasMoreData = true,
    this.isLoadingMore = false,
  });

  PersonLoaded copyWith({
    List<PersonModel>? persons,
    int? currentPage,
    bool? hasMoreData,
    bool? isLoadingMore,
  }) {
    return PersonLoaded(
      persons ?? this.persons,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SinglePersonLoaded extends PersonState {
  final PersonModel person;

  SinglePersonLoaded(this.person);
}

class PersonCubit extends Cubit<PersonState> {
  final PersonService personService;
  List<PersonModel> _persons = [];
  int _currentPage = 0;
  static const int _pageSize = 20;

  PersonCubit(this.personService) : super(PersonInitial());

  Future<void> loadPersons({bool refresh = false}) async {
    if (refresh || state is PersonInitial) {
      _currentPage = 0;
      _persons.clear();
      emit(PersonLoading());
    }

    try {
      final newPersons =
          await personService.getAll(page: _currentPage, size: _pageSize);

      if (refresh || _persons.isEmpty) {
        _persons = newPersons;
      } else {
        _persons.addAll(newPersons);
      }

      final hasMoreData = newPersons.length >= _pageSize;
      emit(PersonLoaded(
        List.unmodifiable(_persons),
        currentPage: _currentPage,
        hasMoreData: hasMoreData,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (!isClosed) {
        emit(PersonInitial());
      }
      rethrow;
    }
  }

  Future<void> loadMorePersons() async {
    final currentState = state;
    if (currentState is PersonLoaded &&
        !currentState.isLoadingMore &&
        currentState.hasMoreData) {
      emit(currentState.copyWith(isLoadingMore: true));

      try {
        _currentPage++;
        final newPersons =
            await personService.getAll(page: _currentPage, size: _pageSize);

        _persons.addAll(newPersons);
        final hasMoreData = newPersons.length >= _pageSize;

        emit(PersonLoaded(
          List.unmodifiable(_persons),
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

  Future<void> createPerson(PersonModel person) async {
    await personService.create(person);
  }

  Future<void> updatePerson(PersonModel person) async {
    await personService.update(person.id!, person);
  }

  Future<void> deletePerson(int id) async {
    await personService.delete(id);
  }

  Future<void> getPersonById(int id) async {
    emit(PersonLoading());
    try {
      final person = await personService.getById(id);
      emit(SinglePersonLoaded(person));
    } catch (e) {
      if (!isClosed) {
        emit(PersonInitial());
      }
      rethrow;
    }
  }

  Future<void> findByName(String name, {int page = 0, int size = 10}) async {
    emit(PersonLoading());
    try {
      final result =
          await personService.findByName(name, page: page, size: size);
      emit(PersonLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(PersonInitial());
      }
      rethrow;
    }
  }

  Future<void> findByNameContaining(String keyword,
      {int page = 0, int size = 10}) async {
    emit(PersonLoading());
    try {
      final result = await personService.findByNameContaining(keyword,
          page: page, size: size);
      emit(PersonLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(PersonInitial());
      }
      rethrow;
    }
  }

  Future<void> findByType(String type, {int page = 0, int size = 10}) async {
    emit(PersonLoading());
    try {
      final result =
          await personService.findByType(type, page: page, size: size);
      emit(PersonLoaded(List.unmodifiable(result)));
    } catch (e) {
      if (!isClosed) {
        emit(PersonInitial());
      }
      rethrow;
    }
  }

  Future<void> findByEmail(String email) async {
    emit(PersonLoading());
    try {
      final person = await personService.findByEmail(email);
      emit(SinglePersonLoaded(person));
    } catch (e) {
      if (!isClosed) {
        emit(PersonInitial());
      }
      rethrow;
    }
  }

  Future<void> findByIdentification(int identification) async {
    emit(PersonLoading());
    try {
      final person = await personService.findByIdentification(identification);
      emit(SinglePersonLoaded(person));
    } catch (e) {
      if (!isClosed) {
        emit(PersonInitial());
      }
      rethrow;
    }
  }

  void resetState() {
    emit(PersonInitial());
  }
}
