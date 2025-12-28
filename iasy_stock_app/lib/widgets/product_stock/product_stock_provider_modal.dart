import 'package:flutter/material.dart';

import '../../models/menu/person_model.dart';
import '../../services/product_stock/product_stock_service.dart';
import '../../theme/app_colors.dart';

class ProductStockProviderModal extends StatefulWidget {
  final ProductStockService productStockService;
  final ValueChanged<PersonModel> onProviderSelected;

  const ProductStockProviderModal({
    super.key,
    required this.productStockService,
    required this.onProviderSelected,
  });

  @override
  State<ProductStockProviderModal> createState() =>
      _ProductStockProviderModalState();
}

class _ProductStockProviderModalState extends State<ProductStockProviderModal> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  List<PersonModel> _providers = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isCreating = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);

    try {
      final providers = await widget.productStockService.getProviders(size: 30);
      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar proveedores: $e');
    }
  }

  Future<void> _searchProviders(String query) async {
    if (query.isEmpty) {
      await _loadProviders();
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final providers = await widget.productStockService.getProviders(
        searchQuery: query,
        size: 30,
      );
      setState(() {
        _providers = providers;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      _showErrorSnackBar('Error al buscar proveedores: $e');
    }
  }

  void _selectProvider(PersonModel provider) {
    widget.onProviderSelected(provider);
  }

  Future<void> _createProvider() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showErrorSnackBar('El nombre del proveedor es obligatorio');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final provider = await widget.productStockService.createProvider(
        name: name,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      setState(() => _isCreating = false);

      _clearForm();
      Navigator.of(context).pop();
      _selectProvider(provider);
    } catch (e) {
      setState(() => _isCreating = false);
      _showErrorSnackBar('Error al crear proveedor: $e');
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  void _showCreateProviderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo proveedor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: _inputDecoration('Nombre *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: _inputDecoration('Correo'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: _inputDecoration('Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: _inputDecoration('Dirección'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearForm();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isCreating ? null : _createProvider,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary(context),
              foregroundColor: AppColors.onPrimary,
            ),
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Crear'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceEmphasis(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.surfaceBorder(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.surfaceBorder(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary(context)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger(context),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info(context),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            _buildHeader(theme),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProviderList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Icon(Icons.store_rounded, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Seleccionar proveedor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _showCreateProviderDialog,
                    icon: Icon(Icons.add_circle,
                        size: 18, color: theme.primaryColor),
                    label: const Text('Nuevo'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: theme.primaryColor,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _searchProviders,
            decoration: InputDecoration(
              prefixIcon:
                  Icon(Icons.search, color: AppColors.textMuted(context)),
              hintText: 'Busca por nombre o correo',
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchProviders('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.surfaceBorder(context)),
              ),
              filled: true,
              fillColor: AppColors.surfaceEmphasis(context),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.surfaceBorder(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderList() {
    if (_providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded,
                size: 64, color: AppColors.iconMuted(context)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No hay proveedores registrados'
                  : 'No se encontraron resultados',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMuted(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Crea un proveedor para continuar'
                  : 'Prueba con otro término de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.iconMuted(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _providers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final provider = _providers[index];
        return _buildProviderTile(provider);
      },
    );
  }

  Widget _buildProviderTile(PersonModel provider) {
    return InkWell(
      onTap: () => _selectProvider(provider),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder(context)),
          color: AppColors.surfaceBase,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.info(context).withOpacity(0.12),
              child: Text(
                _getInitials(provider.name),
                style: TextStyle(
                  color: AppColors.info(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (provider.email != null && provider.email!.isNotEmpty)
                    _buildInfoRow(Icons.email_rounded, provider.email!),
                  if (provider.cellPhone != null)
                    _buildInfoRow(
                        Icons.phone_rounded, provider.cellPhone.toString()),
                  if (provider.address != null && provider.address!.isNotEmpty)
                    _buildInfoRow(Icons.location_on_rounded, provider.address!),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.iconMuted(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.iconMuted(context)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
