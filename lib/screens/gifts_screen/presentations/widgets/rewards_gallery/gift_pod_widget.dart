import 'dart:math';
import 'package:bharat_ace/screens/gifts_screen/models/gift_model.dart';
import 'package:bharat_ace/screens/gifts_screen/presentations/providers/rewards_providers.dart';
import 'package:bharat_ace/screens/gifts_screen/presentations/screens/gift_unveiling_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// CHANGED to ConsumerStatefulWidget
class GiftPodWidget extends ConsumerStatefulWidget {
  final Gift gift;
  // final StudentProgress studentProgress; // We'll get this via ref
  final bool isUnlocked; // This can be passed or derived from progress via ref

  const GiftPodWidget({
    super.key,
    required this.gift,
    // required this.studentProgress, // No longer passed directly
    required this.isUnlocked,
  });

  @override
  ConsumerState<GiftPodWidget> createState() =>
      _GiftPodWidgetState(); // CHANGED
}

// CHANGED to ConsumerState<_GiftPodWidget>
class _GiftPodWidgetState extends ConsumerState<GiftPodWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _unlockAnimationController;
  late Animation<double> _revealAnimation;
  late Animation<Color?> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _unlockAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _unlockAnimationController, curve: Curves.easeInOutCubic),
    );

    _glowAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.amber.withOpacity(0.5),
    ).animate(
      CurvedAnimation(
          parent: _unlockAnimationController, curve: Curves.elasticOut),
    );

    // Access widget.isUnlocked directly
    if (widget.isUnlocked && !_unlockAnimationController.isCompleted) {
      _unlockAnimationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant GiftPodWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Access widget.isUnlocked directly
    if (widget.isUnlocked && !oldWidget.isUnlocked) {
      _unlockAnimationController.forward();
    } else if (!widget.isUnlocked && oldWidget.isUnlocked) {
      _unlockAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _unlockAnimationController.dispose();
    super.dispose();
  }

  // REMOVED WidgetRef ref from build method parameters, access via this.ref
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch student progress using this.ref
    final studentProgressAsync = ref.watch(studentProgressProvider);

    return studentProgressAsync.when(
      data: (studentProgress) {
        final completedTests =
            studentProgress.getCompletedTestsForGift(widget.gift.id);
        final bool isAlreadyClaimed =
            studentProgress.isGiftClaimed(widget.gift.id);
        final bool currentIsUnlocked = widget
            .isUnlocked; // Use passed isUnlocked or re-evaluate from progress

        // Logic for the unlock animation based on currentIsUnlocked and isAlreadyClaimed
        // If you want the animation to play when !isAlreadyClaimed and currentIsUnlocked
        if (currentIsUnlocked &&
            !isAlreadyClaimed &&
            !_unlockAnimationController.isAnimating) {
          if (_unlockAnimationController.status == AnimationStatus.dismissed) {
            _unlockAnimationController.forward();
          }
        } else if ((!currentIsUnlocked || isAlreadyClaimed) &&
            !_unlockAnimationController.isAnimating) {
          if (_unlockAnimationController.status == AnimationStatus.completed) {
            _unlockAnimationController.reverse();
          }
        }
        return AnimatedBuilder(
            animation: _unlockAnimationController,
            builder: (context, child) {
              return Card(
                elevation: currentIsUnlocked && !isAlreadyClaimed
                    ? 8 +
                        (((_glowAnimation.value?.alpha ?? 0) > 0
                            ? 4
                            : 0)) // Adjusted glow logic
                    : 2,
                shadowColor: currentIsUnlocked && !isAlreadyClaimed
                    ? _glowAnimation.value
                    : Colors.black.withOpacity(0.5),
                color: currentIsUnlocked
                    ? (isAlreadyClaimed
                        ? Colors.grey[700]?.withOpacity(0.7)
                        : Colors.purple[700]?.withOpacity(0.8))
                    : Colors.deepPurple[700]?.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: currentIsUnlocked
                        ? (isAlreadyClaimed ? Colors.grey[500]! : Colors.amber)
                        : Colors.white24,
                    width: currentIsUnlocked ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: (currentIsUnlocked && !isAlreadyClaimed)
                      ? () {
                          ref
                              .read(selectedGiftForUnveilingProvider.notifier)
                              .state = widget.gift;
                          ref
                              .read(studentProgressProvider.notifier)
                              .claimGift(widget.gift.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const GiftUnveilingScreen()),
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 31,
                          width: 80,
                          child: CustomPaint(
                            painter: _GiftIconPainter(
                              giftId: widget.gift.id,
                              animationValue: _revealAnimation
                                  .value, // Use reveal animation for icon
                              isUnlocked: currentIsUnlocked,
                              isClaimed:
                                  isAlreadyClaimed, // Pass claimed status
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.gift.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (!currentIsUnlocked) ...[
                          _buildProgressChip(
                              "XP: ${studentProgress.currentXp}/${widget.gift.xpRequired}",
                              studentProgress.currentXp /
                                  widget.gift.xpRequired,
                              context),
                          _buildProgressChip(
                              "Streak: ${studentProgress.consistencyStreakDays}/${widget.gift.consistencyDaysRequired}",
                              studentProgress.consistencyStreakDays /
                                  widget.gift.consistencyDaysRequired,
                              context),
                          _buildProgressChip(
                              "Tests: $completedTests/${widget.gift.testsRequired}",
                              completedTests / widget.gift.testsRequired,
                              context),
                        ] else if (currentIsUnlocked && !isAlreadyClaimed) ...[
                          // Use _revealAnimation for the "UNLOCKED!" text too, or a separate one
                          Opacity(
                            opacity:
                                _revealAnimation.value, // Fade in with reveal
                            child: Transform.scale(
                              scale:
                                  1 + (_unlockAnimationController.value * 0.1),
                              child: Text(
                                "UNLOCKED!",
                                style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.greenAccent,
                                    fontSize: 14,
                                    shadows: [
                                      const Shadow(
                                          blurRadius: 8,
                                          color: Colors.greenAccent)
                                    ]),
                              ),
                            ),
                          ),
                        ] else if (isAlreadyClaimed) ...[
                          Text(
                            "CLAIMED", // Simpler text for claimed
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (currentIsUnlocked)
                          ElevatedButton(
                            onPressed: (isAlreadyClaimed)
                                ? null
                                : () {
                                    ref
                                        .read(selectedGiftForUnveilingProvider
                                            .notifier)
                                        .state = widget.gift;
                                    ref
                                        .read(studentProgressProvider.notifier)
                                        .claimGift(widget.gift.id);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const GiftUnveilingScreen()),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAlreadyClaimed
                                  ? Colors.grey[600]
                                  : Colors.greenAccent,
                              foregroundColor: isAlreadyClaimed
                                  ? Colors.white70
                                  : Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                            child:
                                Text(isAlreadyClaimed ? "CLAIMED" : "CLAIM!"),
                          )
                        else if (!currentIsUnlocked) // Add a placeholder for the button area if not unlocked
                          const SizedBox(height: 36), // Approx height of button
                      ],
                    ),
                  ),
                ),
              );
            });
      },
      loading: () => const Card(
        child: Center(
            child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        )),
      ),
      error: (error, stack) => Card(
        child: Center(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Error\n$error",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
        )),
      ),
    );
  }

  Widget _buildProgressChip(
      String text, double progress, BuildContext context) {
    // ... (same as before)
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 2,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0
                  ? Colors.greenAccent
                  : Colors.lightBlueAccent),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _GiftIconPainter extends CustomPainter {
  final String giftId;
  final double animationValue; // 0.0 (locked) to 1.0 (unlocked)
  final bool isUnlocked;
  final bool isClaimed; // ADDED

  // Cache paints that are reused
  // ... other potentially reusable paints ...
  _GiftIconPainter({
    required this.giftId,
    required this.animationValue,
    required this.isUnlocked,
    required this.isClaimed, // ADDED
  });
  final Paint _basePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  final Paint _lockPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;
  final Paint _liquidPaint = Paint(); // For science kit
  final Paint _antennaPaint = Paint(); // For robot
  final Paint _robotEyePaint = Paint()..color = Colors.black;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (isClaimed) {
      _basePaint.color = Colors.grey[500]!;
    } else {
      _basePaint.color =
          Color.lerp(Colors.grey[600], Colors.amberAccent, animationValue)!;
    }
    if (!isUnlocked && animationValue < 0.1) {
      _lockPaint.color = Colors.grey[700]!;
      _drawLock(canvas, center, size,
          _lockPaint.color); // Pass color instead of Paint
    } else {
      double currentAnimValue = isClaimed ? 1.0 : animationValue;

      if (giftId.contains('science_kit')) {
        _drawScienceKit(
            canvas, center, size, _basePaint, currentAnimValue, isClaimed);
      } else if (giftId.contains('telescope')) {
        _drawTelescope(
            canvas, center, size, _basePaint, currentAnimValue, isClaimed);
      } else if (giftId.contains('robot')) {
        _drawRobot(
            canvas, center, size, _basePaint, currentAnimValue, isClaimed);
      } else {
        _drawGiftBox(
            canvas, center, size, _basePaint, currentAnimValue, isClaimed);
      }
      if (isClaimed) {
        Paint checkMarkPaint = Paint()
          ..color = Colors.greenAccent.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 // Thinner checkmark
          ..strokeCap = StrokeCap.round;
        Path checkPath = Path();
        checkPath.moveTo(size.width * 0.35,
            size.height * 0.5); // Adjusted checkmark position/size
        checkPath.lineTo(size.width * 0.48, size.height * 0.65);
        checkPath.lineTo(size.width * 0.7, size.height * 0.4);
        canvas.drawPath(checkPath, checkMarkPaint);
      }
    }
  }

  void _drawLock(Canvas canvas, Offset center, Size size, Color color) {
    final lockPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final lockBodyHeight = size.height * 0.3;
    final lockBodyWidth = size.width * 0.4;
    final lockShackleRadius = size.width * 0.15;

    // Lock body
    final bodyRect = Rect.fromCenter(
        center: Offset(center.dx, center.dy + lockShackleRadius * 0.5),
        width: lockBodyWidth,
        height: lockBodyHeight);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(4)), lockPaint);

    // Lock shackle (arc)
    lockPaint.style = PaintingStyle.stroke;
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(center.dx, center.dy - lockShackleRadius * 0.3),
            radius: lockShackleRadius),
        pi, // Start angle (180 degrees)
        pi, // Sweep angle (180 degrees)
        false,
        lockPaint);
    // Shackle vertical lines
    canvas.drawLine(
        Offset(
            center.dx - lockShackleRadius, center.dy - lockShackleRadius * 0.3),
        Offset(
            center.dx - lockShackleRadius,
            center.dy +
                lockShackleRadius * 0.5 -
                lockBodyHeight / 2 +
                2), // connect to body
        lockPaint);
    canvas.drawLine(
        Offset(
            center.dx + lockShackleRadius, center.dy - lockShackleRadius * 0.3),
        Offset(center.dx + lockShackleRadius,
            center.dy + lockShackleRadius * 0.5 - lockBodyHeight / 2 + 2),
        lockPaint);
  }

  void _drawGiftBox(Canvas canvas, Offset center, Size size, Paint paint,
      double animValue, bool isClaimed) {
    paint.style = PaintingStyle.fill;
    paint.color = isClaimed
        ? Colors.grey[600]!
        : Color.lerp(Colors.blueGrey, Colors.deepPurpleAccent, animValue)!;
    final boxRect = Rect.fromCenter(
        center: center, width: size.width * 0.6, height: size.height * 0.5);
    canvas.drawRRect(
        RRect.fromRectAndRadius(boxRect, const Radius.circular(5)), paint);

    if (!isClaimed && animValue > 0.7) {
      // Only draw ribbon if not claimed and substantially revealed
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3.0 * animValue;
      paint.color =
          Color.lerp(Colors.transparent, Colors.yellowAccent, animValue)!;
      // Lid line
      canvas.drawLine(Offset(boxRect.left, boxRect.top + boxRect.height * 0.25),
          Offset(boxRect.right, boxRect.top + boxRect.height * 0.25), paint);
      // Vertical ribbon
      canvas.drawLine(Offset(center.dx, boxRect.top),
          Offset(center.dx, boxRect.bottom), paint);
      // Horizontal ribbon
      canvas.drawLine(Offset(boxRect.left, center.dy - boxRect.height * 0.05),
          Offset(boxRect.right, center.dy - boxRect.height * 0.05), paint);
    }
  }

  void _drawScienceKit(Canvas canvas, Offset center, Size size, Paint paint,
      double animValue, bool isClaimed) {
    // Beaker
    final beakerWidth = size.width * 0.3 * animValue;
    final beakerHeight = size.height * 0.5 * animValue;
    if (beakerWidth < 2) return; // Don't draw if too small

    Path beakerPath = Path();
    beakerPath.moveTo(center.dx - beakerWidth / 2,
        center.dy + beakerHeight / 2); // bottom-left
    beakerPath.lineTo(center.dx - beakerWidth / 2 * 0.8,
        center.dy - beakerHeight / 2 * 0.8); // mid-left narrowing
    beakerPath.lineTo(center.dx - beakerWidth / 2 * 0.9,
        center.dy - beakerHeight / 2); // top-left wider
    beakerPath.lineTo(center.dx + beakerWidth / 2 * 0.9,
        center.dy - beakerHeight / 2); // top-right wider
    beakerPath.lineTo(center.dx + beakerWidth / 2 * 0.8,
        center.dy - beakerHeight / 2 * 0.8); // mid-right narrowing
    beakerPath.lineTo(center.dx + beakerWidth / 2,
        center.dy + beakerHeight / 2); // bottom-right
    beakerPath.close();
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(beakerPath, paint);

    // "Liquid" inside beaker
    if (animValue > 0.5) {
      Paint liquidPaint = Paint()
        ..color = Color.lerp(Colors.transparent,
            Colors.lightBlueAccent.withOpacity(0.7), (animValue - 0.5) * 2)!;
      canvas.drawRect(
          Rect.fromLTRB(
              center.dx - beakerWidth / 2 + paint.strokeWidth,
              center.dy + beakerHeight * 0.1,
              center.dx + beakerWidth / 2 - paint.strokeWidth,
              center.dy + beakerHeight / 2 - paint.strokeWidth),
          liquidPaint);
    }

    // Test tube (angled)
    final tubeLength = size.height * 0.4 * animValue;
    final tubeWidth = size.width * 0.15 * animValue;
    if (tubeLength < 2) return;

    canvas.save();
    canvas.translate(
        center.dx + size.width * 0.15, center.dy - size.height * 0.1);
    canvas.rotate(pi / 6); // Rotate 30 degrees
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                -tubeWidth / 2, -tubeLength / 2, tubeWidth, tubeLength),
            Radius.circular(tubeWidth / 3)),
        paint);
    canvas.restore();
  }

  void _drawTelescope(Canvas canvas, Offset center, Size size, Paint paint,
      double animValue, bool isClaimed) {
    // Main tube
    final tubeLength = size.width * 0.6 * animValue;
    final tubeWidth = size.height * 0.2 * animValue;
    if (tubeLength < 2) return;

    paint.style = PaintingStyle.fill;
    paint.color =
        Color.lerp(Colors.blueGrey[700]!, Colors.lightBlue[200]!, animValue)!;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-pi / 6); // Angle the telescope

    // Main tube
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                -tubeLength / 2, -tubeWidth / 2, tubeLength, tubeWidth),
            Radius.circular(tubeWidth / 4)),
        paint);

    // Eyepiece
    final eyepieceLength = tubeLength * 0.2;
    final eyepieceWidth = tubeWidth * 0.8;
    canvas.drawRect(
        Rect.fromLTWH(tubeLength / 2 - eyepieceLength * 0.2, -eyepieceWidth / 2,
            eyepieceLength, eyepieceWidth),
        paint..color = Color.lerp(Colors.grey[800]!, Colors.black, animValue)!);

    // Stand (simple tripod leg)
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3 * animValue;
    paint.color = Color.lerp(Colors.grey[600]!, Colors.grey[400]!, animValue)!;
    canvas.drawLine(const Offset(0, 0), Offset(0, tubeWidth * 1.5),
        paint); // Simplified stand
    canvas.restore();
  }

  void _drawRobot(Canvas canvas, Offset center, Size size, Paint paint,
      double animValue, bool isClaimed) {
    if (animValue < 0.1) return; // Don't draw if not visible enough

    paint.style = PaintingStyle.fill;

    // Body
    final bodyWidth = size.width * 0.4 * animValue;
    final bodyHeight = size.height * 0.5 * animValue;
    paint.color = Color.lerp(Colors.grey[700]!, Colors.cyanAccent, animValue)!;
    final bodyRect =
        Rect.fromCenter(center: center, width: bodyWidth, height: bodyHeight);
    canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(5)), paint);

    // Head
    final headRadius = bodyWidth * 0.4;
    paint.color =
        Color.lerp(Colors.grey[600]!, Colors.lightBlueAccent, animValue)!;
    canvas.drawCircle(
        Offset(center.dx, center.dy - bodyHeight / 2 - headRadius * 0.8),
        headRadius,
        paint);

    // Eye (simple dot)
    if (animValue > 0.5) {
      paint.color = Colors.black;
      canvas.drawCircle(
          Offset(center.dx, center.dy - bodyHeight / 2 - headRadius * 0.8),
          headRadius * 0.3,
          paint);
    }

    // Antenna (blinking light)
    if (animValue > 0.3) {
      Paint antennaPaint = Paint()
        ..color = Colors.grey[400]!
        ..strokeWidth = 2.0 * animValue;
      final antennaBaseX = center.dx + headRadius * 0.3;
      final antennaBaseY = center.dy - bodyHeight / 2 - headRadius * 1.5;
      canvas.drawLine(Offset(antennaBaseX, antennaBaseY + headRadius * 0.4),
          Offset(antennaBaseX, antennaBaseY), antennaPaint);

      // Blinking light at the top
      // Use sin wave based on real time or a separate animation controller for blinking
      double blinkFactor =
          (sin(DateTime.now().millisecondsSinceEpoch / 200.0) + 1) / 2.0;
      Paint lightPaint = Paint()
        ..color = Color.lerp(Colors.red[300]!, Colors.red[700]!, blinkFactor)!;
      if (isUnlocked) {
        // Only blink if unlocked
        canvas.drawCircle(Offset(antennaBaseX, antennaBaseY),
            headRadius * 0.15 * animValue * blinkFactor, lightPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GiftIconPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isUnlocked != isUnlocked ||
        oldDelegate.isClaimed != isClaimed ||
        oldDelegate.giftId != giftId;
  }
}
