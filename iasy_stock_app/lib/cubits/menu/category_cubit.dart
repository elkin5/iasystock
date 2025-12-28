import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/category_model.dart';
import '../../services/menu/category_service.dart';

sealed class CategoryState {}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  final int currentPage;
  final bool hasMoreData;
  final bool isLoadingMore;

  CategoryLoaded(
    this.categories, {
    this.currentPage = 0,
    this.hasMoreData = true,
    this.isLoadingMore = false,
  });

  CategoryLoaded copyWith({
    List<CategoryModel>? categories,
    int? currentPage,
    bool? hasMoreData,
    bool? isLoadingMore,
  }) {
    return CategoryLoaded(
      categories ?? this.categories,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SingleCategoryLoaded extends CategoryState {
  final CategoryModel category;

  SingleCategoryLoaded(this.category);
}

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryService categoryService;
  List<CategoryModel> _categories = [];
  int _currentPage = 0;
  static const int _pageSize = 20;

  CategoryCubit(this.categoryService) : super(CategoryInitial());

  Future<void> loadCategories({bool refresh = false}) async {
    final currentState = state;
    // Avoid refetching when we already have categories cached, otherwise duplicates appear
    if (!refresh && currentState is CategoryLoaded && _categories.isNotEmpty) {
      return;
    }

    _currentPage = 0;
    _categories = [];
    emit(CategoryLoading());

    try {
      final newCategories =
          await categoryService.getAll(page: _currentPage, size: _pageSize);

      _categories = newCategories;
      final hasMoreData = newCategories.length >= _pageSize;

      emit(CategoryLoaded(
        List.unmodifiable(_categories),
        currentPage: _currentPage,
        hasMoreData: hasMoreData,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(CategoryInitial());
      rethrow;
    }
  }

  Future<void> loadMoreCategories() async {
    final currentState = state;
    if (currentState is CategoryLoaded &&
        !currentState.isLoadingMore &&
        currentState.hasMoreData) {
      emit(currentState.copyWith(isLoadingMore: true));

      try {
        _currentPage++;
        final newCategories =
            await categoryService.getAll(page: _currentPage, size: _pageSize);

        _categories.addAll(newCategories);
        final hasMoreData = newCategories.length >= _pageSize;

        emit(CategoryLoaded(
          List.unmodifiable(_categories),
          currentPage: _currentPage,
          hasMoreData: hasMoreData,
          isLoadingMore: false,
        ));
      } catch (e) {
        _currentPage--;
        emit(currentState.copyWith(isLoadingMore: false));
        rethrow;
      }
    }
  }

  Future<void> createCategory(CategoryModel category) async {
    await categoryService.create(category);
  }

  Future<void> updateCategory(CategoryModel category) async {
    await categoryService.update(category.id!, category);
  }

  Future<void> deleteCategory(int id) async {
    await categoryService.delete(id);
  }

  Future<void> getCategoryById(int id) async {
    emit(CategoryLoading());
    try {
      final category = await categoryService.getById(id);
      emit(SingleCategoryLoaded(category));
    } catch (e) {
      emit(CategoryInitial());
      rethrow;
    }
  }

  Future<void> findByName(String name, {int page = 0, int size = 10}) async {
    emit(CategoryLoading());
    try {
      final result =
          await categoryService.findByName(name, page: page, size: size);
      emit(CategoryLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(CategoryInitial());
      rethrow;
    }
  }

  Future<void> findByNameContaining(String name,
      {int page = 0, int size = 10}) async {
    emit(CategoryLoading());
    try {
      final result = await categoryService.findByNameContaining(name,
          page: page, size: size);
      emit(CategoryLoaded(List.unmodifiable(result)));
    } catch (e) {
      emit(CategoryInitial());
      rethrow;
    }
  }

  void resetState() {
    emit(CategoryInitial());
  }
}
