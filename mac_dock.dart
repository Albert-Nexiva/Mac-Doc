import 'dart:ui';

import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// Dock of the reorderable [items].
class Dock<T> extends StatefulWidget {
  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  /// Tracks the currently dragged item's index.
  int? draggedIndex;

  /// Tracks the currently hovered item's index.
  int? hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _items.length,
          (index) {
            final item = _items[index];

            return DragTarget<int>(
              onWillAcceptWithDetails: (oldIndex) => oldIndex.data != index,
              onAcceptWithDetails: (oldIndex) {
                setState(() {
                  final draggedItem = _items.removeAt(oldIndex.data);
                  _items.insert(index, draggedItem);
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Draggable<int>(
                  data: index,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.scale(
                      scale: 1.2,
                      child: widget.builder(item),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: widget.builder(item),
                  ),
                  onDragStarted: () {
                    setState(() {
                      draggedIndex = index;
                    });
                  },
                  onDragEnd: (details) {
                    setState(() {
                      draggedIndex = null;
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (event) {
                      setState(() {
                        hoveredIndex = index;
                      });
                    },
                    onExit: (event) {
                      setState(() {
                        hoveredIndex = null;
                      });
                    },
                    child: Tooltip(
                      message: item == Icons.person
                          ? 'Person'
                          : item == Icons.message
                              ? 'Message'
                              : item == Icons.call
                                  ? 'Call'
                                  : item == Icons.camera
                                      ? 'Camera'
                                      : 'Photo',
                      verticalOffset: 20,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        transform: Matrix4.identity()
                          ..translate(0.0, getTranslationY(index), 0.0),
                        height: getScaledSize(index),
                        width: getScaledSize(index),
                        alignment: AlignmentDirectional.bottomCenter,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: getScaledSize(index),
                            ),
                            child: widget.builder(item),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  double getPropertyValue({
    required int index,
    required double baseValue,
    required double maxValue,
    required double nonHoveredMaxValue,
  }) {
    late final double propertyValue;

    if (hoveredIndex == null) {
      return baseValue;
    }

    final difference = (hoveredIndex! - index).abs();
    final itemsAffected = _items.length;

    if (difference == 0) {
      propertyValue = maxValue;
    } else if (difference <= itemsAffected) {
      final ratio = (itemsAffected - difference) / itemsAffected;
      propertyValue = lerpDouble(baseValue, nonHoveredMaxValue, ratio)!;
    } else {
      propertyValue = baseValue;
    }

    return propertyValue;
  }

  double getScaledSize(int index) {
    return getPropertyValue(
      index: index,
      baseValue: 48,
      maxValue: 70,
      nonHoveredMaxValue: 50,
    );
  }

  double getTranslationY(int index) {
    return getPropertyValue(
      index: index,
      baseValue: 0.0,
      maxValue: -22,
      nonHoveredMaxValue: -14,
    );
  }
}
