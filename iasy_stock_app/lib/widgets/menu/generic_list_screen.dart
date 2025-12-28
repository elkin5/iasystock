import 'package:flutter/material.dart';

/// Widget base de detalle que ya teníamos
class EntityDetailDialog extends StatelessWidget {
  final String title;
  final Map<String, String> fields;

  const EntityDetailDialog(
      {super.key, required this.title, required this.fields});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: fields.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${entry.key}: ",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(entry.value)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'))
      ],
    );
  }
}

/// Pantalla genérica con scroll infinito
class GenericInfiniteListScreen<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String searchHint;
  final String Function(T item) searchTextExtractor;
  final Widget Function(BuildContext, T item) itemBuilder;
  final VoidCallback onAddPressed;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final bool hasMoreData;

  const GenericInfiniteListScreen({
    super.key,
    required this.title,
    required this.items,
    required this.searchHint,
    required this.searchTextExtractor,
    required this.itemBuilder,
    required this.onAddPressed,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMoreData = true,
  });

  @override
  State<GenericInfiniteListScreen<T>> createState() =>
      _GenericInfiniteListScreenState<T>();
}

class _GenericInfiniteListScreenState<T>
    extends State<GenericInfiniteListScreen<T>> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items.where((item) {
      return widget
          .searchTextExtractor(item)
          .toLowerCase()
          .contains(_searchQuery);
    }).toList();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  void _onScroll() {
    if (_isBottom &&
        !widget.isLoadingMore &&
        widget.hasMoreData &&
        _searchQuery.isEmpty) {
      widget.onLoadMore?.call();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= (maxScroll * 0.8); // Cargar cuando llegue al 80%
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.onAddPressed,
            tooltip: 'Agregar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => _onSearchChanged(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: widget.searchHint,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(child: Text('No se encontraron resultados.'))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredItems.length +
                          (widget.isLoadingMore && _searchQuery.isEmpty
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredItems.length &&
                            widget.isLoadingMore &&
                            _searchQuery.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = filteredItems[index];
                        return widget.itemBuilder(context, item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla genérica original (mantener compatibilidad)
class GenericListScreen<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String searchHint;
  final String Function(T item) searchTextExtractor;
  final Widget Function(BuildContext, T item) itemBuilder;
  final VoidCallback onAddPressed;

  const GenericListScreen({
    super.key,
    required this.title,
    required this.items,
    required this.searchHint,
    required this.searchTextExtractor,
    required this.itemBuilder,
    required this.onAddPressed,
  });

  @override
  State<GenericListScreen<T>> createState() => _GenericListScreenState<T>();
}

class _GenericListScreenState<T> extends State<GenericListScreen<T>> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items.where((item) {
      return widget
          .searchTextExtractor(item)
          .toLowerCase()
          .contains(_searchQuery);
    }).toList();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.onAddPressed,
            tooltip: 'Agregar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => _onSearchChanged(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: widget.searchHint,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredItems.isEmpty
                  ? const Center(child: Text('No se encontraron resultados.'))
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return widget.itemBuilder(context, item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
