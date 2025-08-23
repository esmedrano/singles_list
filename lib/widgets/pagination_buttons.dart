import 'package:flutter/material.dart';

class PaginationButtons extends StatelessWidget {
  final int currentPage;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  const PaginationButtons({
    super.key,
    required this.currentPage,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: hasPreviousPage ? onPreviousPage : null,
            child: const Text('Previous Page'),
          ),
          Text('Page $currentPage'),
          ElevatedButton(
            onPressed: hasNextPage ? onNextPage : null,
            child: const Text('Next Page'),
          ),
        ],
      ),
    );
  }
}