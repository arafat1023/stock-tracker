import 'package:flutter/material.dart';
import '../models/shop.dart';

class SearchableShopSelector extends StatefulWidget {
  final List<Shop> shops;
  final Shop? selectedShop;
  final ValueChanged<Shop?> onChanged;
  final String? labelText;
  final String? hintText;

  const SearchableShopSelector({
    super.key,
    required this.shops,
    required this.onChanged,
    this.selectedShop,
    this.labelText = 'Shop',
    this.hintText = 'Search and select a shop',
  });

  @override
  State<SearchableShopSelector> createState() => _SearchableShopSelectorState();
}

class _SearchableShopSelectorState extends State<SearchableShopSelector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showDropdown = false;
  List<Shop> _filteredShops = [];

  @override
  void initState() {
    super.initState();
    _filteredShops = widget.shops;
    if (widget.selectedShop != null) {
      _controller.text = widget.selectedShop!.name;
    }

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _showDropdown = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterShops(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredShops = widget.shops;
      } else {
        _filteredShops = widget.shops
            .where((shop) => shop.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _showDropdown = query.isNotEmpty || _filteredShops.isNotEmpty;
    });
  }

  void _selectShop(Shop shop) {
    setState(() {
      _controller.text = shop.name;
      _showDropdown = false;
    });
    widget.onChanged(shop);
    _focusNode.unfocus();
  }

  void _clearSelection() {
    setState(() {
      _controller.clear();
      _filteredShops = widget.shops;
      _showDropdown = false;
    });
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.store),
            suffixIcon: widget.selectedShop != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSelection,
                  )
                : const Icon(Icons.arrow_drop_down),
          ),
          onChanged: _filterShops,
          onTap: () {
            setState(() {
              _showDropdown = true;
              _filteredShops = widget.shops;
            });
          },
          validator: (value) {
            if (widget.selectedShop == null) {
              return 'Please select a shop';
            }
            return null;
          },
        ),
        if (_showDropdown && _filteredShops.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredShops.length,
              itemBuilder: (context, index) {
                final shop = _filteredShops[index];
                return ListTile(
                  title: Text(shop.name),
                  subtitle: shop.address.isNotEmpty ? Text(shop.address) : null,
                  leading: const Icon(Icons.store, size: 20),
                  onTap: () => _selectShop(shop),
                  dense: true,
                );
              },
            ),
          ),
        if (_showDropdown && _filteredShops.isEmpty && _controller.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).cardColor,
            ),
            child: const Text(
              'No shops found',
              style: TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}