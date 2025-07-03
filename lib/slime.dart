import 'dart:async';
import 'package:flutter/material.dart';

class Slime extends StatefulWidget {
  final double scale;

  const Slime({super.key, this.scale = 180});

  @override
  State<Slime> createState() => _SlimeState();
}

class _SlimeState extends State<Slime> with TickerProviderStateMixin {
  bool isJumping = false;
  int currentFrame = 0;
  late Timer frameTimer;
  late List<String> idleFrames;
  late List<String> jumpFrames;
  bool isSlidingUp = false;

  @override
  void initState() {
    super.initState();

    idleFrames = List.generate(10, (i) => 'assets/slime_idle/idle00${i}.png');
    jumpFrames = List.generate(5, (i) => 'assets/slime_jump/jump00${i}.png');
    jumpFrames.add('assets/slime_jump/jump005.png');
    jumpFrames.add('assets/slime_jump/jump006.png');
    jumpFrames.add('assets/slime_jump/jump004.png');
    jumpFrames.add('assets/slime_jump/jump003.png');

    frameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (isJumping) {
          currentFrame++;

          if (currentFrame == 4) {
            isSlidingUp = true;
          }

          if (currentFrame == jumpFrames.length - 3) {
            isSlidingUp = false;
          }

          if (currentFrame >= jumpFrames.length) {
            isJumping = false;
            currentFrame = 0;
            isSlidingUp = false;
          }
        } else {
          currentFrame = (currentFrame + 1) % idleFrames.length;
        }
      });
    });
  }

  void _triggerJump() {
    if (!isJumping) {
      setState(() {
        isJumping = true;
        currentFrame = 0;
        isSlidingUp = false;
      });
    }
  }

  @override
  void dispose() {
    frameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final framePath = isJumping
        ? jumpFrames[currentFrame.clamp(0, jumpFrames.length - 1)]
        : idleFrames[currentFrame % idleFrames.length];

    return GestureDetector(
      onTap: _triggerJump,
      child: AnimatedSlide(
        offset: isSlidingUp ? const Offset(0, -0.3) : Offset.zero,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Image.asset(
          framePath,
          width: widget.scale,
          height: widget.scale,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
