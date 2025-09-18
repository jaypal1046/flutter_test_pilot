// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import '../../step_result.dart';
// import '../../test_action.dart';

// /// Pinch gesture for zoom operations
// class Pinch extends TestAction {
//   final PinchType type;
//   final double? scale;
//   final String? targetKey;
//   final String? targetText;
//   final Type? targetType;
//   final Offset? center;
//   final Duration duration;
//   final PinchContext? context;

//   const Pinch._({
//     required this.type,
//     this.scale,
//     this.targetKey,
//     this.targetText,
//     this.targetType,
//     this.center,
//     this.duration = const Duration(milliseconds: 500),
//     this.context,
//   });

//   /// Pinch to zoom in
//   factory Pinch.zoomIn({
//     double scale = 2.0,
//     String? onText,
//     String? onKey,
//     Type? onType,