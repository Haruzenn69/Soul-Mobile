import 'package:flutter/material.dart';

class PaginatedList<T> extends StatefulWidget {
  const PaginatedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.pageSize = 10,
    this.padding = const EdgeInsets.all(16),
    this.separatorBuilder,
    this.emptyBuilder,
    this.physics,
    this.loadMoreLabel = 'Muat lebih banyak',
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int pageSize;
  final EdgeInsetsGeometry padding;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final WidgetBuilder? emptyBuilder;
  final ScrollPhysics? physics;
  final String loadMoreLabel;

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  int _visible = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant PaginatedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.pageSize != widget.pageSize) {
      _reset();
    }
  }

  void _reset() {
    if (widget.items.isEmpty) {
      _visible = 0;
      return;
    }
    _visible = widget.pageSize;
    if (_visible > widget.items.length) {
      _visible = widget.items.length;
    }
  }

  void _loadMore() {
    if (_visible >= widget.items.length) return;
    setState(() {
      _visible += widget.pageSize;
      if (_visible > widget.items.length) {
        _visible = widget.items.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    final data = widget.items.take(_visible).toList(growable: false);
    final hasMore = _visible < widget.items.length;

    if (widget.separatorBuilder != null) {
      return ListView.separated(
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: data.length + (hasMore ? 1 : 0),
        separatorBuilder: (context, index) {
          if (hasMore && index >= data.length - 1) {
            return const SizedBox.shrink();
          }
          return widget.separatorBuilder!(context, index);
        },
        itemBuilder: (context, index) {
          if (hasMore && index == data.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(widget.loadMoreLabel),
                ),
              ),
            );
          }
          return widget.itemBuilder(context, data[index], index);
        },
      );
    }

    return ListView.builder(
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: data.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasMore && index == data.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(widget.loadMoreLabel),
              ),
            ),
          );
        }
        return widget.itemBuilder(context, data[index], index);
      },
    );
  }
}
