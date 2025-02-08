import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steper Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Steper Example'),
        ),
        // body: SteperItemSection(
        //   contentWidget: CustomContentWidget(),
        // ),
        body: StepperWidget(
          currentStep: 2,
          stepsCount: 5,
          labels: [
            'Submitted',
            'Bank Review',
            'Physical Verification',
            'Final Approval',
            'Account Activation',
          ],
        ),
      ),
    );
  }
}



class CircleWithRotatingArc extends StatefulWidget {
  final double size;
  final Color circleColor;
  final Color arcColor;

  const CircleWithRotatingArc({
    super.key,
    this.size = 100.0,
    this.circleColor = Colors.green,
    this.arcColor = Colors.blue,
  });

  @override
  State<CircleWithRotatingArc> createState() => _CircleWithRotatingArcState();
}

class _CircleWithRotatingArcState extends State<CircleWithRotatingArc>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: CircleArcPainter(
            progress: _controller.value,
            circleColor: widget.circleColor,
            arcColor: widget.arcColor,
          ),
        );
      },
    );
  }
}

class CircleArcPainter extends CustomPainter {
  final double progress;
  final Color circleColor;
  final Color arcColor;

  CircleArcPainter({
    required this.progress,
    required this.circleColor,
    required this.arcColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the green circle
    final circlePaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 5, circlePaint);

    // Draw the rotating arc
    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -pi / 2 + (2 * pi * progress);
    const sweepAngle = pi; // Half circle

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(CircleArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.circleColor != circleColor ||
        oldDelegate.arcColor != arcColor;
  }
}

class StepperWidget extends StatelessWidget {
  final int currentStep;
  final int stepsCount;
  final List<String> labels;

  const StepperWidget({
    Key? key,
    required this.currentStep,
    required this.stepsCount,
    required this.labels,
  })  : assert(currentStep >= 0 && currentStep < stepsCount),
        assert(labels.length == stepsCount),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100, // Adjust height as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stepsCount,
        itemBuilder: (context, index) {
          return buildStep(index);
        },
      ),
    );
  }

  Widget buildStep(int index) {
    final isActive = index == currentStep;
    final isCompleted = index < currentStep;

    return InkWell(
      // Make steps tappable if needed
      onTap: () {
        // Handle tap, e.g., navigate to the step's content
        if (index < currentStep) {
          // Only allow tapping on previous steps
          print('Navigating to step ${index + 1}');
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // buildCircle(index, isActive, isCompleted),
          CircleWithRotatingArc(
            size: 30.0, // Reduced size for stepper
            circleColor: Colors.green,
            arcColor: Colors.blue,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: Text(
              labels[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isCompleted
                    ? Colors.black
                    : (isActive ? Colors.blue : Colors.grey),
                fontWeight: isCompleted || isActive
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCircle(int index, bool isActive, bool isCompleted) {
    Color circleColor;
    IconData? icon;

    if (isCompleted) {
      circleColor = Colors.green;
      icon = Icons.check;
    } else if (isActive) {
      circleColor = Colors.blue;
      icon = Icons.fiber_manual_record;
    } else {
      circleColor = Colors.grey;
      icon = Icons.fiber_manual_record_outlined;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          backgroundColor: circleColor,
          radius: 16, // Adjust radius as needed
        ),
        if (icon != null)
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
      ],
    );
  }
}
