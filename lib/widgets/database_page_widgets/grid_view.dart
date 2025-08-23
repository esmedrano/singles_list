import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:integra_date/databases/sqlite_database.dart' as sqlite;
import 'package:integra_date/widgets/share_popup.dart';

class BoxView extends StatefulWidget {
  const BoxView({
    super.key,
    required this.scrollController,
    required this.profileData,
    required this.isLoading,
    required this.initialOffset,
    required this.switchPage,
  });

  final ScrollController scrollController;
  final Future<List<Map<dynamic, dynamic>>> profileData;
  final bool isLoading;
  final double initialOffset;
  final Function(int, int?) switchPage;

  @override
  _BoxViewState createState() => _BoxViewState();
}

class _BoxViewState extends State<BoxView> with TickerProviderStateMixin {
  late double _initialOffset;
  double _scale = 4.0;
  int _crossAxisCount = 3;
  final double _minScale = 0.2;
  final double _maxScale = 7.8;
  bool jumpedOnce = false;
  bool _isPinching = false;
  int _pointerCount = 0;
  AnimationController? _animationController;
  Timer? _debounceTimer;
  final double _baseColumnCount = 3.0;
  bool zoomingIn = false;
  bool zoomingOut = false;
  bool snapped = true;
  DateTime? _lastScaleEndTime;
  static const _debounceDuration = Duration(milliseconds: 100);
  bool _isBuilding = false;
  bool recalculateOffset = false;

  @override
  void initState() {
    super.initState();
    _initialOffset = widget.initialOffset;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  SliverGridDelegate _buildGridDelegate() {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _crossAxisCount,
      childAspectRatio: 1.0,
      mainAxisSpacing: 2.0,
      crossAxisSpacing: 2.0,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    setState(() {
      _isPinching = _pointerCount >= 2;
    });
    _debounceTimer?.cancel();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (_animationController!.isAnimating) return;

      setState(() {
        snapped = false;
        double pinchDistance = details.focalPointDelta.distance;
        double zoomDirection = details.scale > 1.0 ? 1.0 : -1.0;
        const double percentagePerPixel = 0.05;
        double scaleChange = pinchDistance * percentagePerPixel * zoomDirection;
        _scale = (_scale + scaleChange).clamp(_minScale, _maxScale);

        if (zoomDirection > 0) {
          zoomingIn = true;
        } else {
          zoomingOut = true;
        }

        if (_scale < 4.0) {
          _crossAxisCount = 5;
        } else if (_scale >= _maxScale) {
          _crossAxisCount = 1;
        } else {
          _crossAxisCount = 3;
        }
      });
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _debounceTimer?.cancel();
    final now = DateTime.now();
    if (_lastScaleEndTime != null &&
        now.difference(_lastScaleEndTime!) < _debounceDuration) {
      return;
    }
    _lastScaleEndTime = now;

    if (!snapped && !_isBuilding) {
      setState(() {
        _isPinching = false;
        _snapToNearestColumn();
        zoomingIn = false;
        zoomingOut = false;
        snapped = true;
      });
    }
  }

  void _snapToNearestColumn() {
    if (_animationController!.isAnimating) return;

    double targetScale;
    int targetCrossAxisCount;

    recalculateOffset = true;
    jumpedOnce = false;

    if (_scale < 4.0) {
      targetScale = zoomingOut ? _minScale : 4.0;
      targetCrossAxisCount = zoomingOut ? 5 : 3;
    } else if (_scale > 4.0) {
      targetScale = zoomingIn ? _maxScale : 4.0;
      targetCrossAxisCount = zoomingIn ? 1 : 3;
    } else {
      targetScale = 4.0;
      targetCrossAxisCount = 3;
    }

    if (_scale != targetScale || _crossAxisCount != targetCrossAxisCount) {
      _animationController!.reset();
      final scaleAnimation = Tween<double>(begin: _scale, end: targetScale).animate(
        CurvedAnimation(parent: _animationController!, curve: Easing.standardDecelerate),
      );

      void update() {
        setState(() {
          _scale = scaleAnimation.value;
          if (_scale == targetScale) {
            _crossAxisCount = targetCrossAxisCount;
          }
        });
      }

      scaleAnimation.addListener(update);
      _animationController!.forward();

      scaleAnimation.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          scaleAnimation.removeListener(update);
          if (recalculateOffset && widget.scrollController.hasClients) {
            final gridItemHeight = _crossAxisCount == 5
                ? (context.size!.width - 8.0) / 5
                : _crossAxisCount == 1
                    ? context.size!.width
                    : (context.size!.width - 4.0) / 3;

            final previousItemHeight = _scale < 4.0
                ? (context.size!.width - 4.0) / 3
                : _scale >= _maxScale
                    ? context.size!.width
                    : (context.size!.width - 8.0) / 5;

            int firstVisibleRow = (widget.scrollController.offset / previousItemHeight).floor();
            int firstVisibleIndex = firstVisibleRow * _crossAxisCount;

            if (_crossAxisCount == 1) {
              _initialOffset = firstVisibleIndex * gridItemHeight;
            } else if (_crossAxisCount == 3) {
              _initialOffset = (firstVisibleIndex / 3 * gridItemHeight).ceil().toDouble();
            } else if (_crossAxisCount == 5) {
              _initialOffset = (firstVisibleIndex / 5 * gridItemHeight).ceil().toDouble();
            }

            widget.scrollController.jumpTo(
              _initialOffset.clamp(0.0, widget.scrollController.position.maxScrollExtent),
            );
            recalculateOffset = false;
            jumpedOnce = true;
          }
        }
      });
    }
  }

  void _toggleZoom() {
    setState(() {
      if (_scale == 4.0) {
        _scale = _maxScale;
        _crossAxisCount = 1;
      } else {
        _scale = 4.0;
        _crossAxisCount = 3;
      }
    });
    _snapToNearestColumn();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isBuilding = true;
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisSpacing = 2.0;
        final oneColumnItemWidth = constraints.maxWidth;
        final baseTotalSpacing = crossAxisSpacing * (_baseColumnCount - 1);
        final baseGridItemWidth = (constraints.maxWidth - baseTotalSpacing) / _baseColumnCount;
        final fiveColumnTotalSpacing = crossAxisSpacing * (5 - 1);
        final fiveColumnItemWidth = (constraints.maxWidth - fiveColumnTotalSpacing) / 5;

        final gridItemWidth = _crossAxisCount == 5 && _scale <= _minScale
            ? fiveColumnItemWidth
            : _crossAxisCount == 1 && _scale >= _maxScale
                ? oneColumnItemWidth
                : baseGridItemWidth;

        double scaleFactor;
        if (_crossAxisCount == 5) {
          scaleFactor = _scale <= _minScale ? 1.0 : lerpDouble(1.0, 1.65, (_scale - _minScale) / (4.0 - _minScale))!;
        } else if (_crossAxisCount == 3 && _scale > 4.0) {
          scaleFactor = lerpDouble(1.0, 3.5, (_scale - 4.0) / (_maxScale - 4.0))!;
        } else if (_crossAxisCount == 1) {
          scaleFactor = _scale >= _maxScale ? 1.0 : lerpDouble(0.5, 1.0, (_scale - 4.0) / (_maxScale - 4.0))!;
        } else {
          scaleFactor = _scale / 4.0;
        }

        return FutureBuilder<List<Map<dynamic, dynamic>>>(
          future: widget.profileData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No profiles available'));
            }

            final profiles = snapshot.data!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (widget.scrollController.hasClients &&
                  widget.scrollController.offset != _initialOffset &&
                  !jumpedOnce &&
                  _initialOffset != 0) {
                widget.scrollController.jumpTo(
                  _initialOffset.clamp(0.0, widget.scrollController.position.maxScrollExtent),
                );
                jumpedOnce = true;
              }
              _isBuilding = false;
            });

            return Listener(
              onPointerDown: (event) {
                setState(() {
                  _pointerCount += 1;
                  _isPinching = _pointerCount >= 2;
                });
              },
              onPointerUp: (event) {
                setState(() {
                  _pointerCount = (_pointerCount - 1).clamp(0, 10);
                  _isPinching = _pointerCount >= 2;
                });
              },
              onPointerCancel: (event) {
                setState(() {
                  _pointerCount = (_pointerCount - 1).clamp(0, 10);
                  _isPinching = _pointerCount >= 2;
                });
              },
              child: GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                onDoubleTap: _pointerCount == 1 ? _toggleZoom : null,
                behavior: HitTestBehavior.translucent,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) => _isPinching,
                  child: ClipRect(
                    child: Transform.scale(
                      scale: scaleFactor,
                      alignment: Alignment.center,
                      child: GridView.builder(
                        physics: _isPinching
                            ? const NeverScrollableScrollPhysics()
                            : const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 30),
                        controller: widget.scrollController,
                        itemCount: profiles.length + (widget.isLoading ? 1 : 0),
                        gridDelegate: _buildGridDelegate(),
                        itemBuilder: (context, index) {
                          if (index == profiles.length) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: ProfileGridItem(
                              profile: profiles[index],
                              gridItemWidth: gridItemWidth,
                              index: index,
                              onBannerTap: widget.switchPage,
                              isPinching: _isPinching,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ProfileGridItem extends StatefulWidget {
  const ProfileGridItem({
    super.key,
    required this.profile,
    required this.gridItemWidth,
    required this.index,
    required this.onBannerTap,
    required this.isPinching,
  });

  final Map<dynamic, dynamic> profile;
  final double gridItemWidth;
  final int index;
  final Function(int, int?) onBannerTap;
  final bool isPinching;

  @override
  _ProfileGridItemState createState() => _ProfileGridItemState();
}

class _ProfileGridItemState extends State<ProfileGridItem> {
  bool displayInfo = false;
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.isPinching
          ? null
          : () {
              setState(() {
                displayInfo = !displayInfo;
              });
            },
      onDoubleTap: widget.isPinching ? null : () => widget.onBannerTap(1, widget.index),
      onLongPress: widget.isPinching
          ? null
          : () {
              showProfileDialog(
                context: context,
                imagePath: widget.profile['profilePic'],
                index: widget.index,
                onMenuAction: (action) {
                  print('$action selected for index ${widget.index}');
                },
                tapPosition: _tapPosition ?? Offset.zero,
                profileId: widget.profile['name'],
              );
            },
      onTapDown: (details) {
        setState(() {
          _tapPosition = details.globalPosition;
        });
      },
      splashColor: const Color(0x50FFFFFF),
      splashFactory: InkRipple.splashFactory,
      child: Column(
        children: [
          ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 1, right: 1, bottom: 1),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: FutureBuilder<String?>(
                      future: _getImagePath(widget.profile['profilePic'], widget.profile['name'], context),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final imagePath = snapshot.data;
                        if (imagePath == null || !File(imagePath).existsSync()) {
                          return Container(
                            color: Colors.grey,
                          );
                        }
                        return Ink(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: FileImage(File(imagePath)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 1,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    offset: displayInfo ? Offset.zero : const Offset(0, 1),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: displayInfo ? 1.0 : 0.0,
                      child: SizedBox(
                        width: widget.gridItemWidth,
                        height: 35,
                        child: Container(
                          padding: const EdgeInsets.only(left: 5, right: 5, bottom: 1),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.profile['name']?.toString() ?? 'Unknown',
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        widget.profile['age']?.toString() ?? 'N/A',
                                        style: const TextStyle(fontSize: 10, color: Colors.black),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        widget.profile['height']?.toString() ?? 'N/A',
                                        style: const TextStyle(fontSize: 10, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.profile['distance']?.toString() ?? 'N/A',
                                    style: const TextStyle(fontSize: 10, color: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<String?> _getImagePath(
      String? imagePath, String profileId, BuildContext context) async {
    if (imagePath == null || !File(imagePath).existsSync()) {
      final cachedPath = await sqlite.DatabaseHelper.instance.getCachedImage(
          profileId, widget.profile['images']?.isNotEmpty == true ? widget.profile['images'][0] : '');
      if (cachedPath != null && File(cachedPath).existsSync()) {
        return cachedPath;
      }
      return null; // Return null instead of asset path
    }
    return imagePath;
  }
}

/* import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:integra_date/widgets/share_popup.dart'; // Added: Import the shared dialog function

class BoxView extends StatefulWidget {
  const BoxView({
    super.key,
    required this.scrollController,
    required this.profileData,
    required this.isLoading,
    required this.initialOffset,
    required this.switchPage,
  });

  final ScrollController scrollController;
  final Future<List<Map<dynamic, dynamic>>> profileData;
  final bool isLoading;
  final double initialOffset;
  final Function(int, int?) switchPage;

  @override
  _BoxViewState createState() => _BoxViewState();
}

class _BoxViewState extends State<BoxView> with TickerProviderStateMixin {
  late double _initialOffset;

  double _scale = 4.0;
  int _crossAxisCount = 3;
  final double _minScale = 0.2; // 5 columns
  final double _maxScale = 7.8; // 1 column
  bool jumpedOnce = false;  // Only update the scroll offset if coming from other page 
  bool _isPinching = false;
  int _pointerCount = 0;
  AnimationController? _animationController;
  Timer? _debounceTimer;
  final double _baseColumnCount = 3.0;
  bool zoomingIn = false;
  bool zoomingOut = false;
  bool snapped = true;  // Only snap once per scale update. See _snapToNearestColumn(). For some reason onScaleEnd is called twice
  DateTime? _lastScaleEndTime; // New: Timestamp for debouncing
  static const _debounceDuration = Duration(milliseconds: 100); // New: Debounce window
  bool _isBuilding = false; // New: Track build phase
  bool recalculateOffset = false;  // Recalculate and jump to offset if zoom level changed

  @override
  void initState() {
    super.initState();
     _initialOffset = widget.initialOffset;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  SliverGridDelegate _buildGridDelegate() {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _crossAxisCount,
      childAspectRatio: 1.0,
      mainAxisSpacing: 2.0,
      crossAxisSpacing: 2.0,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    setState(() {
      _isPinching = _pointerCount >= 2;
      
      if (_animationController!.isAnimating) {
        //_animationController!.stop();
        //_animationController!.reset();
      }
    });
    _debounceTimer?.cancel(); // Cancel any existing timer    
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 16), () {
      // Cancel any ongoing animation to prioritize user input
      if (_animationController!.isAnimating) {
        //_animationController!.stop();
        //_animationController!.reset();
      }

      if (_animationController!.isAnimating) return;  // Prevent updates during animation

      setState(() {
        snapped = false;

        double pinchDistance = details.focalPointDelta.distance;  // Calculate pixel movement from focalPointDelta (use magnitude for simplicity)
        double zoomDirection = details.scale > 1.0 ? 1.0 : -1.0;  // Determine direction: positive for pinch-out (zoom-in), negative for pinch-in (zoom-out)
        const double percentagePerPixel = 0.05;  // Fixed percentage change per pixel (e.g., 0.01 = 1% per pixel)
        double scaleChange = pinchDistance * percentagePerPixel * zoomDirection;  // Calculate scale change based on pinch distance
        
        _scale = (_scale + scaleChange).clamp(_minScale, _maxScale);  // Update scale additively
        
        print('SCALE !!!!!!! $_scale');

        if (zoomDirection > 0) {  // Use bools in _snapToNearestColumn function to animate to next column based on user intended direction 
          zoomingIn = true;  // These are reset in _onScaleEnd function
          print('zoom toggled');
        } else {
          zoomingOut = true;
        }

        // Determine crossAxisCount based on scale
        if (_scale < 4.0) {
          _crossAxisCount = 5;
        } else if (_scale >= _maxScale) {
          _crossAxisCount = 1;  
        } else {
          _crossAxisCount = 3;
        }
      });
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _debounceTimer?.cancel();

    final now = DateTime.now();  // Only 
    if (_lastScaleEndTime != null &&
        now.difference(_lastScaleEndTime!) < _debounceDuration) {
      return;
    }
    _lastScaleEndTime = now;
    
    if (!snapped && !_isBuilding) {  // It snapps twice every time for some reason. It must call _onScaleEnd twice. This is partial fix
      setState(() {
        _isPinching = false;  // Reset pinching state
        _snapToNearestColumn();
        print('snapped');
        zoomingIn = false;
        zoomingOut = false;
        snapped = true;
      });
    }
  }
  
  void _snapToNearestColumn() {
  if (_animationController!.isAnimating) {
    return;
  }

  double targetScale;
  int targetCrossAxisCount;

  recalculateOffset = true;
  jumpedOnce = false; // Reset jumpedOnce to allow jump after recalculation

  print('ZOOM ??? $zoomingIn');

  if (_scale < 4.0) {
    targetScale = zoomingOut ? _minScale : 4.0;
    targetCrossAxisCount = zoomingOut ? 5 : 3;
  } else if (_scale > 4.0) {
    targetScale = zoomingIn ? _maxScale : 4.0;
    targetCrossAxisCount = zoomingIn ? 1 : 3;
  } else {
    targetScale = 4.0;
    targetCrossAxisCount = 3;
  }

  print('zoomingIn: $zoomingIn');
  print('target scale: $targetScale');
  print('targetCrossAxisCount: $targetCrossAxisCount');

  if (_scale != targetScale || _crossAxisCount != targetCrossAxisCount) {
    _animationController!.reset();

    final scaleAnimation = Tween<double>(begin: _scale, end: targetScale).animate(
      CurvedAnimation(parent: _animationController!, curve: Easing.standardDecelerate),
    );

    void update() {
      setState(() {
        _scale = scaleAnimation.value;
        print(_scale);

        if (_scale == targetScale) {
          _crossAxisCount = targetCrossAxisCount;
        }
      });
    }

    scaleAnimation.addListener(update);
    _animationController!.forward();

    scaleAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        scaleAnimation.removeListener(update);
        // Recalculate offset and jump after animation completes
        if (recalculateOffset && widget.scrollController.hasClients) {
          final gridItemHeight = _crossAxisCount == 5
              ? (context.size!.width - 8.0) / 5 // 5 columns, 2.0 spacing * 4
              : _crossAxisCount == 1
                  ? context.size!.width // 1 column, no spacing
                  : (context.size!.width - 4.0) / 3; // 3 columns, 2.0 spacing * 2

          // Determine previous layout's item height for accurate index calculation
          final previousItemHeight = _scale < 4.0
              ? (context.size!.width - 4.0) / 3 // Was 3 columns
              : _scale >= _maxScale
                  ? context.size!.width // Was 1 column
                  : (context.size!.width - 8.0) / 5; // Was 5 columns

          // Calculate first visible row based on previous layout
          int firstVisibleRow = (widget.scrollController.offset / previousItemHeight).floor();
          // Map to first item in the new layout
          int firstVisibleIndex = firstVisibleRow * _crossAxisCount;

          if (_crossAxisCount == 1) {
            _initialOffset = firstVisibleIndex * gridItemHeight;
          } else if (_crossAxisCount == 3) {
            _initialOffset = (firstVisibleIndex / 3 * gridItemHeight).ceil().toDouble();
          } else if (_crossAxisCount == 5) {
            _initialOffset = (firstVisibleIndex / 5 * gridItemHeight).ceil().toDouble();
          }

          widget.scrollController.jumpTo(
            _initialOffset.clamp(0.0, widget.scrollController.position.maxScrollExtent),
          );
          print('Jumped to $_initialOffset (crossAxisCount: $_crossAxisCount, firstVisibleIndex: $firstVisibleIndex, firstVisibleRow: $firstVisibleRow)');
          recalculateOffset = false;
          jumpedOnce = true;
        }
      }
    });
  }
}

  void _toggleZoom() {
    setState(() {
      if (_scale == 4.0) {
        _scale = _maxScale; // Zoom to 1 column
        _crossAxisCount = 1;
      } else {
        _scale = 4.0; // Zoom back to 3 columns
        _crossAxisCount = 3;
      }
    });
    _snapToNearestColumn(); // Ensure smooth snapping
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isBuilding = true; // Set build flag
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisSpacing = 2.0;
        
        final oneColumnItemWidth = constraints.maxWidth;  // Calculate item width for 1 columns
        
        final baseTotalSpacing = crossAxisSpacing * (_baseColumnCount - 1);  
        final baseGridItemWidth = (constraints.maxWidth - baseTotalSpacing) / _baseColumnCount;  // Calculate item width for 3 columns
        
        final fiveColumnTotalSpacing = crossAxisSpacing * (5 - 1);  
        final fiveColumnItemWidth = (constraints.maxWidth - fiveColumnTotalSpacing) / 5;  // Calculate item width for 5 columns

        final gridItemWidth = _crossAxisCount == 5 && _scale <= _minScale  // If clumns == 5
            ? fiveColumnItemWidth  // 5 coulmn width
            : _crossAxisCount == 1  && _scale >= _maxScale  // else if columns == 1
                ? oneColumnItemWidth  // 1 column width
                : baseGridItemWidth;  // else 3 column width

        double scaleFactor;
        if (_crossAxisCount == 5) {  // If 5 and going towards 5 scale from 3-column size to 5-column size
          scaleFactor = _scale <= _minScale ? 1.0 : lerpDouble(1.0, 1.65, (_scale - _minScale) / (4.0 - _minScale))!;
        } 
        else if (_crossAxisCount == 3 && _scale > 4.0 ) {  // If 3 and going towards 1
          scaleFactor = lerpDouble(1.0, 3.5, (_scale - 4.0) / (_maxScale - 4.0))!;
        } 
        else if (_crossAxisCount == 1) {
          scaleFactor = _scale >= _maxScale ? 1.0 : lerpDouble(0.5, 1.0, (_scale - 4.0) / (_maxScale - 4.0))!;
        } 
        else {
          scaleFactor = _scale / 4.0; // Normalize to neutral point
        }

        return FutureBuilder<List<Map<dynamic, dynamic>>>(
          future: widget.profileData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {  // Get profile data
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No profiles available'));
            }

            final profiles = snapshot.data!;  

            WidgetsBinding.instance.addPostFrameCallback((_) {
              
              print(widget.scrollController.offset != _initialOffset);
              print('widget ${widget.scrollController.offset}');
              print(_initialOffset);
              if (widget.scrollController.hasClients &&
                  widget.scrollController.offset != _initialOffset &&
                  !jumpedOnce &&
                  _initialOffset != 0) {

                widget.scrollController.jumpTo(
                  _initialOffset.clamp(0.0, widget.scrollController.position.maxScrollExtent),
                );
                jumpedOnce = true;
              }
              _isBuilding = false; // Reset build flag after build
            });

            return Listener(
              onPointerDown: (event) {
                setState(() {
                  _pointerCount += 1;
                  _isPinching = _pointerCount >= 2;
                });
              },

              onPointerUp: (event) {
                setState(() {
                  _pointerCount = (_pointerCount - 1).clamp(0, 10);
                  _isPinching = _pointerCount >= 2;
                });
              },

              onPointerCancel: (event) {
                setState(() {
                  _pointerCount = (_pointerCount - 1).clamp(0, 10);
                  _isPinching = _pointerCount >= 2;
                });
              },

              child: GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                onDoubleTap: _pointerCount == 1 ? _toggleZoom : null,
                
                behavior: HitTestBehavior.translucent,
                
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) => _isPinching,
                  
                  child: ClipRect(
                    
                    child: Transform.scale(
                      scale: scaleFactor,
                      alignment: Alignment.center,
                      
                      child: GridView.builder(
                        physics: _isPinching
                            ? const NeverScrollableScrollPhysics()
                            : const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 30),
                        controller: widget.scrollController,
                        itemCount: profiles.length + (widget.isLoading ? 1 : 0),
                        
                        gridDelegate: _buildGridDelegate(),
                        
                        itemBuilder: (context, index) {
                          if (index == profiles.length) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: ProfileGridItem(
                              profile: profiles[index],
                              gridItemWidth: gridItemWidth,
                              index: index,
                              onBannerTap: widget.switchPage,
                              isPinching: _isPinching,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ProfileGridItem extends StatefulWidget {
  const ProfileGridItem({
    super.key,
    required this.profile,
    required this.gridItemWidth,
    required this.index,
    required this.onBannerTap,
    required this.isPinching,
  });

  final Map<dynamic, dynamic> profile;
  final double gridItemWidth;
  final int index;
  final Function(int, int?) onBannerTap;
  final bool isPinching;

  @override
  _ProfileGridItemState createState() => _ProfileGridItemState();
}

class _ProfileGridItemState extends State<ProfileGridItem> {
  bool displayInfo = false;
  // Added: Stores the position for the popup menu
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.isPinching
          ? null
          : () {
              setState(() {
                displayInfo = !displayInfo;
              });
            },
      onDoubleTap: widget.isPinching ? null : () => widget.onBannerTap(1, widget.index),
      // Added: Handle long press to show focused image and menu
      onLongPress: widget.isPinching
          ? null
          : () {
              showProfileDialog(
                context: context,
                imagePath: widget.profile['profilePic'] ?? 'assets/profile_image.jpg',
                index: widget.index,
                // Added: Handle menu actions
                onMenuAction: (action) {
                  print('$action selected for index ${widget.index}');
                },
                tapPosition: _tapPosition ?? Offset.zero,
                profileId: widget.profile['name'],
              );
            },
      // Added: Store tap position for long press
      onTapDown: (details) {
        setState(() {
          _tapPosition = details.globalPosition;
        });
      },

      splashColor: const Color(0x50FFFFFF),
      splashFactory: InkRipple.splashFactory,
      child: Column(
        children: [
          ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 1, right: 1, bottom: 1),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Ink(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(widget.profile['profilePic'] ?? 'assets/profile_image.jpg'),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 1,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    offset: displayInfo ? Offset.zero : const Offset(0, 1),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: displayInfo ? 1.0 : 0.0,
                      child: SizedBox(
                        width: widget.gridItemWidth,
                        height: 35,
                        child: Container(
                          padding: const EdgeInsets.only(left: 5, right: 5, bottom: 1),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.profile['name']?.toString() ?? 'Unknown',
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        widget.profile['age']?.toString() ?? 'N/A',
                                        style: const TextStyle(fontSize: 10, color: Colors.black),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        widget.profile['height']?.toString() ?? 'N/A',
                                        style: const TextStyle(fontSize: 10, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.profile['distance']?.toString() ?? 'N/A',
                                    style: const TextStyle(fontSize: 10, color: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} */