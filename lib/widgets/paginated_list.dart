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
      setState(() => _visible = 0);
      return;
    }
    setState(() {
      _visible = widget.pageSize;
      if (_visible > widget.items.length) _visible = widget.items.length;
    });
  }

  void _loadMore() {
    if (_visible >= widget.items.length) return;
    setState(() {
      _visible += widget.pageSize;
      if (_visible > widget.items.length) _visible = widget.items.length;
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
      return Column(
        children: [
          Expanded(
            child: ListView.separated(
              physics: widget.physics,
              padding: widget.padding,
              itemCount: data.length,
              separatorBuilder: widget.separatorBuilder!,
              itemBuilder: (context, index) =>
                  widget.itemBuilder(context, data[index], index),
            ),
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(widget.loadMoreLabel),
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: widget.physics,
            padding: widget.padding,
            itemCount: data.length,
            itemBuilder: (context, index) =>
                widget.itemBuilder(context, data[index], index),
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(widget.loadMoreLabel),
              ),
            ),
          ),
      ],
    );
  }
}
