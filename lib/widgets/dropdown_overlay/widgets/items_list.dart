part of '../../../custom_dropdown.dart';

class _ItemsList<T> extends StatefulWidget {
  final ScrollController scrollController;
  final T? selectedItem;
  final List<T> items, selectedItems;
  final Function(T) onItemSelect;
  final bool excludeSelected;
  final EdgeInsets itemsListPadding, listItemPadding;
  final _ListItemBuilder<T> listItemBuilder;
  final ListItemDecoration? decoration;
  final _DropdownType dropdownType;
  final Future<void> Function()? onLoadMore;
  final bool isLoadingMore;
  final Widget? loadMoreIndicator;

  const _ItemsList({
    super.key,
    required this.scrollController,
    required this.selectedItem,
    required this.items,
    required this.onItemSelect,
    required this.excludeSelected,
    required this.itemsListPadding,
    required this.listItemPadding,
    required this.listItemBuilder,
    required this.selectedItems,
    required this.decoration,
    required this.dropdownType,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.loadMoreIndicator,
  });

  @override
  State<_ItemsList<T>> createState() => _ItemsListState<T>();
}

class _ItemsListState<T> extends State<_ItemsList<T>> {
  bool _isLoading = false;
  Timer? _loadMoreDebouncer;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    _loadMoreDebouncer?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (widget.onLoadMore == null) return;

    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !widget.isLoadingMore) {
        _loadMoreDebouncer?.cancel();
        _loadMoreDebouncer = Timer(const Duration(milliseconds: 200), () {
          if (!_isLoading && !widget.isLoadingMore) {
            _isLoading = true;
            widget.onLoadMore!().then((_) {
              if (mounted) {
                _isLoading = false;
              }
            }).catchError((_) {
              if (mounted) {
                _isLoading = false;
              }
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: widget.scrollController,
      child: ListView.builder(
        controller: widget.scrollController,
        shrinkWrap: true,
        padding: widget.itemsListPadding,
        itemCount: widget.items.length + (widget.onLoadMore != null ? 1 : 0),
        cacheExtent: 1000,
        itemBuilder: (_, index) {
          if (index == widget.items.length) {
            return widget.isLoadingMore
                ? widget.loadMoreIndicator ??
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                : const SizedBox.shrink();
          }

          final selected = switch (widget.dropdownType) {
            _DropdownType.singleSelect => !widget.excludeSelected &&
                widget.selectedItem == widget.items[index],
            _DropdownType.multipleSelect =>
              widget.selectedItems.contains(widget.items[index])
          };

          return Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: widget.decoration?.splashColor ??
                  ListItemDecoration._defaultSplashColor,
              highlightColor: widget.decoration?.highlightColor ??
                  ListItemDecoration._defaultHighlightColor,
              onTap: () => widget.onItemSelect(widget.items[index]),
              child: Ink(
                color: selected
                    ? (widget.decoration?.selectedColor ??
                        ListItemDecoration._defaultSelectedColor)
                    : Colors.transparent,
                padding: widget.listItemPadding,
                child: widget.listItemBuilder(
                  context,
                  widget.items[index],
                  selected,
                  () => widget.onItemSelect(widget.items[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
