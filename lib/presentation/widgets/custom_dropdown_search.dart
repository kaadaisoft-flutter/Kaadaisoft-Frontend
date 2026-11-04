import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const Color primary = Color(0xFF2D1B18);
  static const Color error = Colors.red;
}

class AppTypography {
  static TextStyle inter({Color? color, double? fontSize, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: 'Inter',
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  static TextStyle manrope({Color? color, double? fontSize, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: 'Manrope',
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
}

class CustomDropdownSearch extends StatefulWidget {
  final String label;
  final String? hint;
  final List<String>? dropdownItems;
  final Map<String, String>? dropdownMap; // Map of database ID (value) to Display Name (label)
  final String? value;
  final ValueChanged<String?>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool requiredMark;
  final bool clearOnSelect;
  final bool isEnabled;
  final double height;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double? borderWidth;
  final double? focusedBorderWidth;
  final bool autofocus;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final bool? showSearch;

  const CustomDropdownSearch({
    super.key,
    required this.label,
    this.hint,
    this.dropdownItems,
    this.dropdownMap,
    this.value,
    this.onChanged,
    this.validator,
    this.requiredMark = false,
    this.clearOnSelect = false,
    this.isEnabled = true,
    this.autofocus = false,
    this.height = 44,
    this.borderColor,
    this.focusedBorderColor,
    this.borderWidth,
    this.focusedBorderWidth,
    this.onTap,
    this.isLoading = false,
    this.errorText,
    this.inputFormatters,
    this.showSearch,
  });

  static bool get isOpen => _CustomDropdownSearchState._closeActiveDropdown != null;

  @override
  State<CustomDropdownSearch> createState() => _CustomDropdownSearchState();
}

class _CustomDropdownSearchState extends State<CustomDropdownSearch> with WidgetsBindingObserver {
  static VoidCallback? _closeActiveDropdown;

  final _groupId = Object();
  OverlayEntry? _overlayEntry;
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  /// Controller for the search input field inside the dropdown popup.
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  /// When true, the dropdown list is being actively scrolled on a touch
  /// device. We use this to prevent accidental item selection.
  bool _isScrolling = false;

  List<MapEntry<String, String>> _filteredItems = [];
  int _highlightedIndex = 0;

  Map<String, String> get _allEntries {
    if (widget.dropdownMap != null) {
      return widget.dropdownMap!;
    } else if (widget.dropdownItems != null) {
      return {for (var item in widget.dropdownItems!) item: item};
    }
    return {};
  }

  bool get _shouldShowSearch => widget.showSearch ?? (_allEntries.length > 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _filteredItems = _allEntries.entries.toList();

    _scrollController.addListener(() {
      if (_scrollController.position.isScrollingNotifier.value) {
        _isScrolling = true;
      }
    });

    _searchFocusNode.onKeyEvent = (node, event) => _handleKey(event);
    _mainFocusNode.onKeyEvent = (node, event) => _handleKey(event);
    _searchFocusNode.addListener(_onFocusChange);
    _mainFocusNode.addListener(_onFocusChange);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.autofocus) {
        _mainFocusNode.requestFocus();
      }
    });
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeMetrics() {
    _overlayEntry?.markNeedsBuild();
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (_overlayEntry == null) {
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.arrowDown)) {
        if (_fieldKey.currentState != null) {
          _showDropdown(_fieldKey.currentState!);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _hideDropdown();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_highlightedIndex < _filteredItems.length - 1) {
          _highlightedIndex++;
          _scrollToHighlight();
          _overlayEntry?.markNeedsBuild();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_highlightedIndex > 0) {
          _highlightedIndex--;
          _scrollToHighlight();
          _overlayEntry?.markNeedsBuild();
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_highlightedIndex >= 0 && _highlightedIndex < _filteredItems.length) {
          if (_fieldKey.currentState != null) {
            _selectItem(
              _fieldKey.currentState!,
              _filteredItems[_highlightedIndex],
            );
          }
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void _scrollToHighlight() {
    if (_scrollController.hasClients) {
      const double itemHeight = 40.0;
      final double targetPosition = _highlightedIndex * itemHeight;
      if (targetPosition < _scrollController.position.pixels) {
        _scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      } else if (targetPosition + itemHeight > _scrollController.position.pixels + _scrollController.position.viewportDimension) {
        _scrollController.animateTo(
          targetPosition + itemHeight - _scrollController.position.viewportDimension,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _selectItem(FormFieldState<String> field, MapEntry<String, String> entry) {
    if (widget.clearOnSelect) {
      field.didChange(null);
    } else {
      field.didChange(entry.key);
    }
    _filteredItems = _allEntries.entries.toList();
    _searchController.clear();
    widget.onChanged?.call(entry.key);
    _searchFocusNode.unfocus();
    _mainFocusNode.unfocus();
    _hideDropdown();
  }

  @override
  void didUpdateWidget(CustomDropdownSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value || widget.dropdownMap != oldWidget.dropdownMap || widget.dropdownItems != oldWidget.dropdownItems) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (_fieldKey.currentState != null && _fieldKey.currentState!.value != widget.value) {
            _fieldKey.currentState!.didChange(widget.value);
          }
          setState(() {});
        }
      });
    }
    if (widget.autofocus && !oldWidget.autofocus) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mainFocusNode.requestFocus();
        }
      });
    }
    if (widget.dropdownItems != oldWidget.dropdownItems || widget.dropdownMap != oldWidget.dropdownMap || widget.isLoading != oldWidget.isLoading) {
      _filteredItems = _allEntries.entries.toList();
      if (_overlayEntry != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _overlayEntry?.markNeedsBuild();
          }
        });
      }
    }
  }

  void _filterItems(String query) {
    _highlightedIndex = 0;
    if (query.isEmpty) {
      _filteredItems = _allEntries.entries.toList();
    } else {
      final q = query.toLowerCase().trim();
      _filteredItems = _allEntries.entries.where((entry) => entry.value.toLowerCase().contains(q)).toList();
    }
    _overlayEntry?.markNeedsBuild();
  }

  void _toggleDropdown(FormFieldState<String> field) {
    if (_overlayEntry != null) {
      _hideDropdown();
    } else {
      _showDropdown(field);
    }
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    if (!_scrollController.hasClients) return;
    final double scrollDelta = event.scrollDelta.dy;
    final double newOffset = (_scrollController.offset + scrollDelta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(newOffset);
  }

  void _showDropdown(FormFieldState<String> field) {
    if (!widget.isEnabled) return;
    if (_closeActiveDropdown != null) {
      _closeActiveDropdown!();
    }
    _closeActiveDropdown = _hideDropdown;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _filteredItems = _allEntries.entries.toList();
    _highlightedIndex = 0;
    _searchController.clear();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        const double kDropdownMaxHeight = 320;
        final fieldGlobal = renderBox.localToGlobal(Offset.zero);
        final view = WidgetsBinding.instance.platformDispatcher.views.first;
        final double screenHeight = view.physicalSize.height / view.devicePixelRatio;
        final double keyboardHeight = view.viewInsets.bottom / view.devicePixelRatio;

        final spaceBelow = screenHeight - fieldGlobal.dy - size.height - keyboardHeight - 12;
        final spaceAbove = fieldGlobal.dy - 12;

        final showAbove = spaceBelow < kDropdownMaxHeight && spaceAbove > spaceBelow;

        final double availableSpace = showAbove ? spaceAbove : spaceBelow;
        final double finalMaxHeight = availableSpace < kDropdownMaxHeight
            ? (availableSpace < 160 ? 160 : availableSpace)
            : kDropdownMaxHeight;

        final Offset offset = showAbove ? const Offset(0, -6) : Offset(0, size.height + 6);
        final Alignment tAnchor = showAbove ? Alignment.topLeft : Alignment.topLeft;
        final Alignment fAnchor = showAbove ? Alignment.bottomLeft : Alignment.topLeft;
        final bool isTa = Localizations.localeOf(context).languageCode == 'ta';

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: tAnchor,
            followerAnchor: fAnchor,
            offset: offset,
            child: TapRegion(
              groupId: _groupId,
              child: Material(
                type: MaterialType.card,
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(maxHeight: finalMaxHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_shouldShowSearch) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Icon(
                                      Icons.search,
                                      size: 18,
                                      color: AppColors.primary.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      textInputAction: TextInputAction.search,
                                      decoration: InputDecoration(
                                        hintText: isTa ? 'தேடுக...' : 'Search...',
                                        hintStyle: AppTypography.inter(
                                          color: Colors.grey.shade400,
                                          fontSize: 13,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                                      ),
                                      style: AppTypography.inter(
                                        color: Colors.black87,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      onChanged: (val) {
                                        _filterItems(val);
                                      },
                                    ),
                                  ),
                                  if (_searchController.text.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        _filterItems('');
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Icon(Icons.clear, size: 16, color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                        ],
                        Flexible(
                          child: widget.isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          isTa ? 'ஏற்றுகிறது...' : 'Loading...',
                                          style: AppTypography.inter(
                                            color: Colors.grey.shade500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : _filteredItems.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Text(
                                        isTa ? 'முடிவுகள் எதுவும் இல்லை' : 'No results found',
                                        style: AppTypography.inter(
                                          color: Colors.grey.shade500,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : NotificationListener<ScrollNotification>(
                                      onNotification: (notification) {
                                        if (notification is ScrollStartNotification) {
                                          _isScrolling = true;
                                        } else if (notification is ScrollEndNotification) {
                                          Future.delayed(
                                            const Duration(milliseconds: 150),
                                            () => _isScrolling = false,
                                          );
                                        }
                                        return false;
                                      },
                                      child: Listener(
                                        onPointerSignal: (event) {
                                          if (event is PointerScrollEvent) {
                                            _handlePointerScroll(event);
                                          }
                                        },
                                        child: ScrollConfiguration(
                                          behavior: _TrackpadAwareScrollBehavior(),
                                          child: ListView.builder(
                                            controller: _scrollController,
                                            shrinkWrap: true,
                                            physics: const ClampingScrollPhysics(),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            itemCount: _filteredItems.length,
                                            itemBuilder: (context, index) {
                                              final entry = _filteredItems[index];
                                              final isHighlighted = index == _highlightedIndex;
                                              final isSelected = entry.key == widget.value;

                                              return Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  splashFactory: NoSplash.splashFactory,
                                                  onTap: () {
                                                    if (_isScrolling) return;
                                                    if (_fieldKey.currentState != null) {
                                                      _selectItem(
                                                        _fieldKey.currentState!,
                                                        entry,
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 10,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(6),
                                                      color: isSelected
                                                          ? AppColors.primary.withValues(alpha: 0.08)
                                                          : (isHighlighted ? Colors.grey.shade100 : Colors.transparent),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            entry.value,
                                                            style: AppTypography.inter(
                                                              color: isSelected ? AppColors.primary : Colors.black87,
                                                              fontSize: 14,
                                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                            ),
                                                          ),
                                                        ),
                                                        if (isSelected)
                                                          const Icon(
                                                            Icons.check,
                                                            size: 16,
                                                            color: AppColors.primary,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    if (mounted) setState(() {});

    if (_shouldShowSearch) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  void _hideDropdown() {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
    if (_closeActiveDropdown == _hideDropdown) {
      _closeActiveDropdown = null;
    }
    _highlightedIndex = 0;
    _isScrolling = false;
    _searchController.clear();
    _searchFocusNode.unfocus();
    _filteredItems = _allEntries.entries.toList();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocusNode.removeListener(_onFocusChange);
    _mainFocusNode.removeListener(_onFocusChange);
    if (_closeActiveDropdown == _hideDropdown) {
      _closeActiveDropdown = null;
    }
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mainFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _mainFocusNode,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty) ...[
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${widget.label.replaceAll('*', '').trim()} ',
                    style: AppTypography.manrope(
                      color: (_overlayEntry != null || _mainFocusNode.hasFocus) ? AppColors.primary : Colors.grey.shade800,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.requiredMark || widget.label.contains('*'))
                    const TextSpan(
                      text: '*',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          CompositedTransformTarget(
            link: _layerLink,
            child: FormField<String>(
              key: _fieldKey,
              initialValue: widget.value,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: widget.validator,
              builder: (field) {
                final currentValue = field.value ?? widget.value;
                final displayValue = _allEntries[currentValue] ?? (widget.dropdownMap != null ? '' : currentValue ?? '');
                final hasValue = displayValue.trim().isNotEmpty;
                final isOpen = _overlayEntry != null;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TapRegion(
                      groupId: _groupId,
                      onTapOutside: (_) {
                        _hideDropdown();
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.isEnabled && !widget.isLoading
                              ? () {
                                  widget.onTap?.call();
                                  _toggleDropdown(field);
                                }
                              : null,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            height: widget.height,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            clipBehavior: Clip.none,
                            decoration: BoxDecoration(
                              color: widget.isEnabled ? Colors.white : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                width: (field.hasError || widget.errorText != null)
                                    ? 1.5
                                    : (isOpen || _mainFocusNode.hasFocus)
                                        ? (widget.focusedBorderWidth ?? 1.5)
                                        : (widget.borderWidth ?? 1.0),
                                color: (field.hasError || widget.errorText != null)
                                    ? AppColors.error
                                    : (isOpen || _mainFocusNode.hasFocus)
                                        ? (widget.focusedBorderColor ?? AppColors.primary)
                                        : widget.isEnabled
                                            ? (widget.borderColor ?? AppColors.primary.withValues(alpha: 0.15))
                                            : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    hasValue
                                        ? displayValue
                                        : (widget.hint ??
                                            (Localizations.localeOf(context).languageCode == 'ta'
                                                ? '${widget.label.replaceAll('*', '').trim()} தேர்ந்தெடு'
                                                : 'Select ${widget.label.replaceAll('*', '').trim()}')),
                                    style: AppTypography.inter(
                                      color: hasValue
                                          ? (widget.isEnabled ? Colors.black87 : Colors.grey.shade500)
                                          : Colors.grey.shade400,
                                      fontSize: 14,
                                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.isLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(
                                    isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                    size: 20,
                                    color: widget.isEnabled ? AppColors.primary : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (field.hasError || widget.errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          widget.errorText ?? field.errorText ?? "",
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackpadAwareScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}
