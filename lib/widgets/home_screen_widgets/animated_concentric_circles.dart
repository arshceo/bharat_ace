import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AnimatedConcentricCircles extends StatefulWidget {
  final double screenWidth;

  const AnimatedConcentricCircles({super.key, required this.screenWidth});

  @override
  _AnimatedConcentricCirclesState createState() =>
      _AnimatedConcentricCirclesState();
}

class _AnimatedConcentricCirclesState extends State<AnimatedConcentricCircles> {
  static const Color streakCircleColor = Color.fromRGBO(252, 250, 255, 0.47);
  static const Color iconsCircleColor = Color.fromRGBO(255, 255, 255, 0.47);

  String _selectedTopic = "Calculus";
  final List<String> _topics = [
    "Calculus",
    'Data Structures and Algorithms',
    'ਪੰਜਾਬੀ ਵਿਚ ਦੀ ਕਿਸਮ',
    'data 3',
    'हिन्दी या आधुनिक मानक',
    'data 5',
  ];

  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.screenWidth,
      height: widget.screenWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _buildStreakCircle(),
          _buildMainGoalsCircle(),
          _buildIconsCircle()
        ],
      ),
    );
  }

  Widget _buildStreakCircle() {
    final double circleSize = widget.screenWidth * 0.5;

    return Positioned(
      right: 0,
      bottom: -80,
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: const ShapeDecoration(
          color: streakCircleColor,
          shape: CircleBorder(
            side: BorderSide(width: 1, color: Color(0xFFD6CACA)),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('9 NOV 2025',
                style: TextStyle(fontSize: 12, color: Colors.black)),
            Padding(
              padding: EdgeInsets.all(0.0),
              child: Text('59',
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 182, 72))),
            ),
            Text('days streak',
                style: TextStyle(fontSize: 10, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainGoalsCircle() {
    final double circleSize = widget.screenWidth * 0.75;

    return Container(
      width: circleSize,
      height: circleSize,
      decoration: ShapeDecoration(
        gradient: const RadialGradient(
          center: Alignment(-0.18, 1.09),
          radius: 0.8,
          colors: [
            Color(0xFF7219F8),
            Color(0xFF9648F9),
            Color(0xE5B773FB),
            Color(0xEAC180FC),
          ],
        ),
        shape: const CircleBorder(
          side: BorderSide(
            width: 20,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Color.fromRGBO(255, 255, 255, 0.33),
          ),
        ),
      ),
      child: Stack(
        alignment: AlignmentDirectional.topCenter,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 60.0),
            child: Text(
              "Today's Topics",
              style: TextStyle(
                fontSize: 30,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: CupertinoPicker.builder(
              scrollController: _scrollController,
              diameterRatio: 2,
              itemExtent: 40,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedTopic = _topics[index % _topics.length];
                });
              },
              childCount: _topics.length,
              magnification: 1.75,
              squeeze: 1.1,
              itemBuilder: (context, index) {
                return Center(
                    child: SizedBox(
                  width: 130,
                  child: Text(
                    _topics[index % _topics.length],
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        overflow: TextOverflow.ellipsis),
                  ),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconsCircle() {
    final double circleSize = widget.screenWidth * 0.45;

    return Positioned(
      left: 10,
      bottom: -60,
      child: Container(
        width: circleSize,
        height: circleSize,
        decoration: const ShapeDecoration(
          color: iconsCircleColor,
          shape: CircleBorder(
            side: BorderSide(width: 1, color: Color(0xFFE0CFCF)),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.access_time_filled_outlined,
                    size: 24, color: Colors.white70),
                Icon(Icons.star, size: 24, color: Colors.grey),
                Icon(Icons.favorite, size: 24, color: Colors.white),
              ],
            ),
            SizedBox(height: 8),
            Text('1.2k',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
