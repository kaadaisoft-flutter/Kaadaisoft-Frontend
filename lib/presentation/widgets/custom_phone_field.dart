import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/phone_number.dart';

class CustomPhoneField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Key? fieldKey;
  final FocusNode? focusNode;
  final String? hint;
  final bool isDarkTheme;
  final ValueChanged<Country>? onCountryChanged;
  final bool showDropdownOnRight;
  final String initialCountryCode;

  const CustomPhoneField({
    Key? key,
    required this.label,
    required this.controller,
    this.validator,
    this.fieldKey,
    this.focusNode,
    this.hint,
    this.isDarkTheme = false,
    this.onCountryChanged,
    this.showDropdownOnRight = false,
    this.initialCountryCode = 'IN',
  }) : super(key: key);

  @override
  State<CustomPhoneField> createState() => _CustomPhoneFieldState();
}

class _CustomPhoneFieldState extends State<CustomPhoneField> {
  late Country _selectedCountry;
  OverlayEntry? _countryOverlayEntry;
  final GlobalKey _mobileFieldKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  bool _isCountryDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedCountry = countries.firstWhere((c) => c.code == widget.initialCountryCode, orElse: () => countries.firstWhere((c) => c.code == 'IN'));
  }

  @override
  void didUpdateWidget(CustomPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCountryCode != oldWidget.initialCountryCode) {
      _selectedCountry = countries.firstWhere((c) => c.code == widget.initialCountryCode, orElse: () => countries.firstWhere((c) => c.code == 'IN'));
    }
  }

  void _toggleCountryDropdown() {
    if (_isCountryDropdownOpen) {
      _removeCountryOverlay();
    } else {
      _showCountryOverlay();
    }
  }

  void _showCountryOverlay() {
    final renderBox = _mobileFieldKey.currentContext!.findRenderObject()! as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Check space below (dropdown max height is 320)
    final spaceBelow = screenHeight - offset.dy - size.height;
    final showAbove = spaceBelow < 320 && offset.dy > spaceBelow;
    
    final followerAnchor = showAbove ? Alignment.bottomLeft : Alignment.topLeft;
    final targetAnchor = showAbove ? Alignment.topLeft : Alignment.bottomLeft;
    final yOffset = showAbove ? -4.0 : 4.0;

    _countryOverlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeCountryOverlay,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: targetAnchor,
            followerAnchor: followerAnchor,
            offset: Offset(0, yOffset),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: size.width,
                child: GestureDetector(
                  onTap: () {}, // absorb taps
                  child: _CountryDropdownPanel(
                    initialCountry: _selectedCountry,
                    onSelect: (country) {
                      setState(() => _selectedCountry = country);
                      widget.controller.clear();
                      if (widget.onCountryChanged != null) {
                        widget.onCountryChanged!(country);
                      }
                      _removeCountryOverlay();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_countryOverlayEntry!);
    setState(() => _isCountryDropdownOpen = true);
  }

  void _removeCountryOverlay() {
    _countryOverlayEntry?.remove();
    _countryOverlayEntry = null;
    if (mounted) setState(() => _isCountryDropdownOpen = false);
  }

  @override
  void dispose() {
    _countryOverlayEntry?.remove();
    _countryOverlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasAsterisk = widget.label.contains('*');
    String cleanLabel = widget.label.replaceAll('*', '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cleanLabel.isNotEmpty) ...[
          RichText(
            text: TextSpan(
              text: '$cleanLabel ',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              children: [
                if (hasAsterisk)
                  const TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            key: _mobileFieldKey,
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: TextInputType.phone,
            autovalidateMode: widget.isDarkTheme ? AutovalidateMode.disabled : AutovalidateMode.onUserInteraction,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_selectedCountry.maxLength),
            ],
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: widget.isDarkTheme 
                  ? const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)
                  : const TextStyle(fontSize: 13, color: Colors.grey),
              prefixIcon: widget.showDropdownOnRight ? null : GestureDetector(
                onTap: _toggleCountryDropdown,
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 4),
                      Text(
                        '${_selectedCountry.flag} +${_selectedCountry.dialCode}',
                        style: TextStyle(color: widget.isDarkTheme ? Colors.white : Colors.black87, fontSize: 15),
                      ),
                      Icon(
                        _isCountryDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: widget.isDarkTheme ? Colors.white : Colors.black54,
                      ),
                      Container(
                        height: 22,
                        width: 1,
                        color: widget.isDarkTheme ? Colors.white30 : Colors.grey.shade400,
                        margin: const EdgeInsets.only(left: 4, right: 8),
                      ),
                    ],
                  ),
                ),
              ),
              suffixIcon: widget.showDropdownOnRight ? GestureDetector(
                onTap: _toggleCountryDropdown,
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 22,
                        width: 1,
                        color: widget.isDarkTheme ? Colors.white30 : Colors.grey.shade400,
                        margin: const EdgeInsets.only(left: 8, right: 4),
                      ),
                      Text(
                        '${_selectedCountry.flag} +${_selectedCountry.dialCode}',
                        style: TextStyle(color: widget.isDarkTheme ? Colors.white : Colors.black87, fontSize: 15),
                      ),
                      Icon(
                        _isCountryDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: widget.isDarkTheme ? Colors.white : Colors.black54,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ) : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isDarkTheme ? 30 : 10),
                borderSide: widget.isDarkTheme ? BorderSide.none : const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isDarkTheme ? 30 : 10),
                borderSide: widget.isDarkTheme ? BorderSide.none : const BorderSide(color: Color(0xFFC5A028), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isDarkTheme ? 30 : 10),
                borderSide: widget.isDarkTheme ? BorderSide.none : const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.isDarkTheme ? 30 : 10),
                borderSide: widget.isDarkTheme ? BorderSide.none : const BorderSide(color: Colors.redAccent, width: 2),
              ),
              errorStyle: widget.isDarkTheme ? const TextStyle(height: 0, fontSize: 0, color: Colors.transparent) : null,
              filled: widget.isDarkTheme ? false : true,
              fillColor: widget.isDarkTheme ? Colors.transparent : Colors.white.withOpacity(0.9),
              contentPadding: widget.isDarkTheme 
                  ? const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: TextStyle(
              color: widget.isDarkTheme ? Colors.white : Colors.black87,
            ),
            cursorColor: widget.isDarkTheme ? Colors.white : null,
            validator: (value) {
              final val = widget.controller.text.replaceAll(' ', '').trim();
              if (val.isNotEmpty) {
                if (_selectedCountry.code == 'IN') {
                  if (!RegExp(r'^[6-9]').hasMatch(val)) {
                    return 'Indian mobile numbers must start with 6, 7, 8, or 9';
                  }
                }
                if (val.length < _selectedCountry.minLength || val.length > _selectedCountry.maxLength) {
                  if (_selectedCountry.minLength == _selectedCountry.maxLength) {
                    return 'Enter a valid ${_selectedCountry.minLength}-digit number';
                  } else {
                    return 'Enter between ${_selectedCountry.minLength} and ${_selectedCountry.maxLength} digits';
                  }
                }
              }
              if (widget.validator != null) {
                return widget.validator!(value);
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class _CountryDropdownPanel extends StatefulWidget {
  final Country initialCountry;
  final ValueChanged<Country> onSelect;

  const _CountryDropdownPanel({
    required this.initialCountry,
    required this.onSelect,
  });

  @override
  State<_CountryDropdownPanel> createState() => _CountryDropdownPanelState();
}

class _CountryDropdownPanelState extends State<_CountryDropdownPanel> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Country> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = List.from(countries);
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = countries
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.dialCode.contains(q))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  hintText: 'Search country or code...',
                  hintStyle: const TextStyle(color: Colors.black54, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFC5A028)),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Colors.black12),
            Flexible(
              child: _filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No results', style: TextStyle(color: Colors.black54)),
                    )
                  : RawScrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 6,
                      radius: const Radius.circular(40),
                      thumbColor: Colors.black26,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final c = _filtered[i];
                            final isSelected = c.code == widget.initialCountry.code;
                            return InkWell(
                              onTap: () => widget.onSelect(c),
                              child: Container(
                                color: isSelected
                                    ? const Color(0xFFC5A028).withOpacity(0.1)
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Text(c.flag, style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        c.name,
                                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '+${c.dialCode}',
                                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
