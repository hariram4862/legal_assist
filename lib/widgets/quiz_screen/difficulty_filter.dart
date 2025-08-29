import 'package:flutter/material.dart';

class DifficultyFilter extends StatelessWidget {
  final String value; // Easy / Medium / Hard / Mixed
  final ValueChanged<String> onChanged;
  const DifficultyFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Difficulty',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      value: value,
      items: const [
        DropdownMenuItem(value: 'Easy', child: Text('Easy')),
        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
        DropdownMenuItem(value: 'Hard', child: Text('Hard')),
        DropdownMenuItem(value: 'Mixed', child: Text('Mixed')),
      ],
      onChanged: (v) => onChanged(v ?? 'Mixed'),
    );
  }
}
