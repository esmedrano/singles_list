
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// Age with always-open pickers and visible labels

Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(flex: 1, child: Text('age')),
    Expanded(
      flex: 4,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Min: $_ageMin', style: TextStyle(fontSize: 14)),
                SizedBox(
                  height: 100,
                  child: CupertinoPicker(
                    itemExtent: 30,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _ageMin = _ageOptions[index];
                        if (_ageMax != '50 +' && _ageOptions.indexOf(_ageMax) < index) {
                          _ageMax = _ageOptions[index]; // Set max to min if min increases past max
                        }
                      });
                    },
                    children: _ageOptions
                        .map((item) => Center(child: Text(item)))
                        .toList(),
                    scrollController: FixedExtentScrollController(initialItem: 0),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Max: $_ageMax', style: TextStyle(fontSize: 14)),
                SizedBox(
                  height: 100,
                  child: CupertinoPicker(
                    itemExtent: 30,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        final newMax = _ageOptions[index];
                        if (newMax != '50 +' || _ageOptions.indexOf(newMax) >= _ageOptions.indexOf(_ageMin)) {
                          _ageMax = newMax; // Only update if new max is >= min
                        }
                      });
                    },
                    children: _ageOptions
                        .map((item) => Center(child: Text(item)))
                        .toList(),
                    scrollController: FixedExtentScrollController(initialItem: 2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ],
),

SizedBox(height: 16),

// Height with always-open pickers and visible labels
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(flex: 1, child: Text('height')),
    Expanded(
      flex: 4,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Min: $_heightMin', style: TextStyle(fontSize: 14)),
                SizedBox(
                  height: 100,
                  child: CupertinoPicker(
                    itemExtent: 30,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _heightMin = _heightOptions[index];
                        final minIndex = index;
                        final maxIndex = _heightOptions.indexOf(_heightMax);
                        if (maxIndex < minIndex) {
                          _heightMax = _heightOptions[minIndex]; // Set max to min if min increases past max
                        }
                      });
                    },
                    children: _heightOptions
                        .map((item) => Center(child: Text(item)))
                        .toList(),
                    scrollController: FixedExtentScrollController(initialItem: 0),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Max: $_heightMax', style: TextStyle(fontSize: 14)),
                SizedBox(
                  height: 100,
                  child: CupertinoPicker(
                    itemExtent: 30,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        final newMax = _heightOptions[index];
                        final minIndex = _heightOptions.indexOf(_heightMin);
                        final maxIndex = index;
                        if (maxIndex >= minIndex) {
                          _heightMax = newMax; // Only update if new max is >= min
                        }
                      });
                    },
                    children: _heightOptions
                        .map((item) => Center(child: Text(item)))
                        .toList(),
                    scrollController: FixedExtentScrollController(initialItem: 2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ],
),