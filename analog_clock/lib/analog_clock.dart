// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:analog_clock/container_hand.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'dart:math' as math;

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

class ClockColors {
  Color h;
  Color m;
  Color s;
  Color c;
  Color background;
  Color textColor;
  ClockColors(
    this.h,
    this.m,
    this.s,
    this.c, {
    this.background,
    this.textColor,
  });
}

class ClockTheme {
  ClockColors light;
  ClockColors dark;
  ClockTheme.generateColors() {
    var colors = Colors.primaries;
    var color = colors[math.Random().nextInt(colors.length)];

    light = ClockColors(
      color.shade700,
      color.shade400,
      color.shade500,
      color.shade500,
      background: color.shade50,
      textColor: Colors.black,
    );
    dark = ClockColors(
      color.shade400,
      color.shade100,
      color.shade200,
      color.shade200,
      background: Colors.black,
      textColor: Colors.white,
    );
  }
}

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';
  Timer _timer;
  ClockTheme _clockTheme = ClockTheme.generateColors();
  final animDuration = Duration(seconds: 1);
  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      if (_now.second == 30 || _now.second == 0)
        _clockTheme = ClockTheme.generateColors();

      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final clockColors = isLightTheme ? _clockTheme.light : _clockTheme.dark;

    final time = DateFormat.Hms().format(DateTime.now());
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(color: clockColors.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_temperature),
          Text(_temperatureRange),
          Text(_condition),
          Text(_location),
        ],
      ),
    );

    final double topSize = 10;
    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: AnimatedContainer(
        duration: Duration(seconds: 1),
        padding: EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: clockColors.background,
          shape: BoxShape.circle,
          border: Border.all(
            width: 20,
            color: clockColors.c,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Example of a hand drawn with [CustomPainter].

            ContainerHand(
              color: Colors.transparent,
              size: 0.5,
              angleRadians: _now.hour * radiansPerHour +
                  (_now.minute / 60) * radiansPerHour,
              width: 40,
              height: 150,
              handColor: clockColors.h,
            ),
            ContainerHand(
              color: Colors.transparent,
              size: 0.8,
              angleRadians: _now.minute * radiansPerTick,
              width: 25,
              height: 140,
              handColor: clockColors.m,
            ),
            ContainerHand(
              color: Colors.transparent,
              size: 0.8,
              angleRadians: _now.second * radiansPerTick,
              width: 8,
              height: 140,
              handColor: clockColors.s,
            ),

            Center(
              child: Container(
                width: topSize,
                height: topSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(width: 1.5, color: clockColors.c),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: weatherInfo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
