import 'package:flutter/material.dart';

import '../../models/menu/person_model.dart';
import '../../services/cart_sale/cart_sale_service.dart';
import '../../theme/app_colors.dart';

class CartSaleClientModal extends StatefulWidget {
  final CartSaleService cartSaleService;
  final Function(PersonModel) onClientSelected;

  const CartSaleClientModal({
    super.key,
    required this.cartSaleService,
    required this.onClientSelected,
  });

  @override
  State<CartSaleClientModal> createState() => _CartSaleClientModalState();
}

class _CartSaleClientModalState extends State<CartSaleClientModal> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  List<PersonModel> _clients = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isCreatingClient = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadClients();
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

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Filtrar solo clientes (tipo 'Customer') siguiendo el patrón del sale_form_screen
      final clients = await widget.cartSaleService.getClientsForCart();
      final customerClients = clients
          .where(
              (client) => client.type == 'Customer' || client.type == 'CLIENT')
          .toList();

      setState(() {
        _clients = customerClients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar clientes: $e');
    }
  }

  Future<void> _searchClients(String query) async {
    if (query.isEmpty) {
      await _loadClients();
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final clients = await widget.cartSaleService.getClientsForCart(
        searchQuery: query,
      );

      // Filtrar solo clientes (tipo 'Customer') siguiendo el patrón del sale_form_screen
      final customerClients = clients
          .where(
              (client) => client.type == 'Customer' || client.type == 'CLIENT')
          .toList();

      setState(() {
        _clients = customerClients;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showErrorSnackBar('Error al buscar clientes: $e');
    }
  }

  void _selectClient(PersonModel client) {
    try {
      widget.onClientSelected(client);
      Navigator.of(context).pop();
    } catch (e) {
      // Cerrar el modal de todas formas
      Navigator.of(context).pop();
    }
  }

  void _useDummyClient() async {
    try {
      final dummyClient = await widget.cartSaleService.getDummyClient();
      _selectClient(dummyClient);
    } catch (e) {
      _showErrorSnackBar('Error al obtener cliente dummy: $e');
    }
  }

  void _showCreateClientDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildCreateClientDialog(),
    );
  }

  Future<void> _createNewClient() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('El nombre del cliente es obligatorio');
      return;
    }

    setState(() {
      _isCreatingClient = true;
    });

    try {
      final newClient = await widget.cartSaleService.createClientFromCart(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
      );

      _selectClient(newClient);
    } catch (e) {
      setState(() {
        _isCreatingClient = false;
      });
      _showErrorSnackBar('Error al crear cliente: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  color: theme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Seleccionar Cliente',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barra de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textMuted(context)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchClients('');
                        },
                        icon: Icon(Icons.clear,
                            color: AppColors.textMuted(context)),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.surfaceBorder(context)),
                ),
                filled: true,
                fillColor: AppColors.surfaceEmphasis(context),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.surfaceBorder(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  _searchClients(value);
                } else if (value.isEmpty) {
                  _searchClients('');
                }
              },
            ),

            const SizedBox(height: 16),

            // Botones de acción rápida
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _useDummyClient,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Cliente Dummy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCreateClientDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Nuevo Cliente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary(context),
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Lista de clientes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildClientList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientList() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clients.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        return _buildClientCard(client);
      },
    );
  }

  Widget _buildClientCard(PersonModel client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectClient(client),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar del cliente siguiendo el patrón del dropdown
              CircleAvatar(
                radius: 25,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  _getClientInitials(client.name ?? 'Cliente'),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Información del cliente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name ?? 'Sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Información de contacto compacta
                    if (client.email != null && client.email!.isNotEmpty) ...[
                      _buildContactInfo(Icons.email, client.email!),
                    ],
                    if (client.cellPhone != null && client.cellPhone! > 0) ...[
                      _buildContactInfo(
                          Icons.phone, _formatPhoneNumber(client.cellPhone!)),
                    ],
                    if (client.address != null &&
                        client.address!.isNotEmpty) ...[
                      _buildContactInfo(Icons.location_on, client.address!),
                    ],
                    // Tipo de cliente
                    if (client.type != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary(context).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          client.type!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Botón seleccionar
              IconButton(
                onPressed: () => _selectClient(client),
                icon: const Icon(Icons.check_circle),
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 64,
            color: AppColors.iconMuted(context),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No hay clientes disponibles'
                : 'No se encontraron clientes',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMuted(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Usa "Nuevo Cliente" para crear uno'
                : 'Intenta con otros términos de búsqueda',
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

  Widget _buildCreateClientDialog() {
    return AlertDialog(
      title: const Text('Nuevo Cliente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Nombre *',
                  hint: 'Ingresa el nombre del cliente'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: _inputDecoration('Email', hint: 'correo@ejemplo.com'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration:
                  _inputDecoration('Teléfono', hint: '+57 300 123 4567'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration:
                  _inputDecoration('Dirección', hint: 'Calle 123 #45-67'),
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
          onPressed: _isCreatingClient ? null : _createNewClient,
          child: _isCreatingClient
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  // Métodos auxiliares siguiendo el patrón del dropdown de clientes
  String _getClientInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'C';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted(context)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhoneNumber(int phoneNumber) {
    final phoneStr = phoneNumber.toString();
    if (phoneStr.length >= 10) {
      return '${phoneStr.substring(0, 3)} ${phoneStr.substring(3, 6)} ${phoneStr.substring(6)}';
    }
    return phoneStr;
  }

  Color _getClientTypeColor(String type) {
    return AppColors.primary(context);
  }
}
