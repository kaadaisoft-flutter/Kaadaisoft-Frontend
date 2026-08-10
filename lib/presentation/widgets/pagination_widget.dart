import 'package:flutter/material.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const PaginationWidget({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  }) : super(key: key);

  List<int?> _getVisiblePages() {
    List<int?> pages = [];
    if (totalPages <= 7) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      if (currentPage <= 4) {
        for (int i = 1; i <= 5; i++) {
          pages.add(i);
        }
        pages.add(null);
        pages.add(totalPages);
      } else if (currentPage >= totalPages - 3) {
        pages.add(1);
        pages.add(null);
        for (int i = totalPages - 4; i <= totalPages; i++) {
          pages.add(i);
        }
      } else {
        pages.add(1);
        pages.add(null);
        pages.add(currentPage - 1);
        pages.add(currentPage);
        pages.add(currentPage + 1);
        pages.add(null);
        pages.add(totalPages);
      }
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          color: const Color(0xFF5D1712),
          splashRadius: 20,
        ),
        ..._getVisiblePages().map((page) {
          if (page == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...', style: TextStyle(color: Colors.black54)),
            );
          }
          final isActive = page == currentPage;
          return Padding(
            padding: const EdgeInsets.all(2),
            child: InkWell(
              onTap: () => onPageChanged(page),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2D1B18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isActive ? null : Border.all(color: Colors.black12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$page',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black54,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          color: const Color(0xFF5D1712),
          splashRadius: 20,
        ),
      ],
    );
  }
}
