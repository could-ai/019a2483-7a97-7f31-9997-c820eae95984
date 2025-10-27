import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const AviatorPredictorApp());
}

class AviatorPredictorApp extends StatelessWidget {
  const AviatorPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aviator Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AviatorPredictorHomePage(),
    );
  }
}

class AviatorPredictorHomePage extends StatefulWidget {
  const AviatorPredictorHomePage({super.key});

  @override
  State<AviatorPredictorHomePage> createState() => _AviatorPredictorHomePageState();
}

class _AviatorPredictorHomePageState extends State<AviatorPredictorHomePage>
    with TickerProviderStateMixin {
  double currentMultiplier = 1.0;
  bool isFlying = false;
  bool isCrashed = false;
  double betAmount = 100.0;
  double potentialWin = 0.0;
  List<double> history = [];
  Timer? _timer;
  late AnimationController _planeController;
  late Animation<double> _planeAnimation;
  Random random = Random();

  // Prediction logic
  double suggestedCashOut = 1.5;
  String predictionReason = "Based on average crash at 1.5x";

  @override
  void initState() {
    super.initState();
    _planeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _planeAnimation = Tween<double>(begin: 0, end: 1).animate(_planeController);
    _calculatePrediction();
  }

  void _calculatePrediction() {
    if (history.isEmpty) {
      suggestedCashOut = 1.5;
      predictionReason = "Default suggestion - cash out early for safety";
    } else {
      double avg = history.reduce((a, b) => a + b) / history.length;
      suggestedCashOut = avg * 0.8; // Suggest 80% of average
      predictionReason = "Based on ${history.length} games, avg crash at ${avg.toStringAsFixed(2)}x";
    }
  }

  void _startGame() {
    if (isFlying) return;
    setState(() {
      isFlying = true;
      isCrashed = false;
      currentMultiplier = 1.0;
      potentialWin = betAmount;
    });
    _planeController.reset();
    _planeController.forward();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        currentMultiplier += 0.01 + random.nextDouble() * 0.05;
        potentialWin = betAmount * currentMultiplier;

        // Random crash simulation
        if (random.nextDouble() < 0.02 || currentMultiplier > 10.0) {
          _crashGame();
          timer.cancel();
        }
      });
    });
  }

  void _cashOut() {
    if (!isFlying || isCrashed) return;
    _timer?.cancel();
    setState(() {
      isFlying = false;
      history.add(currentMultiplier);
      _calculatePrediction();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cashed out at ${currentMultiplier.toStringAsFixed(2)}x! Won: ₹${potentialWin.toStringAsFixed(2)}')),
    );
  }

  void _crashGame() {
    _timer?.cancel();
    setState(() {
      isFlying = false;
      isCrashed = true;
      history.add(currentMultiplier);
      _calculatePrediction();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plane crashed! You lost your bet.')),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _planeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aviator Predictor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Multiplier Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isCrashed ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${currentMultiplier.toStringAsFixed(2)}x',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            // Plane Animation
            AnimatedBuilder(
              animation: _planeAnimation,
              builder: (context, child) {
                return Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[200]!, Colors.blue[600]!],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: _planeAnimation.value * (MediaQuery.of(context).size.width - 100),
                        top: 20,
                        child: Icon(
                          Icons.airplanemode_active,
                          size: 60,
                          color: isCrashed ? Colors.red : Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Betting Interface
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isFlying ? null : _startGame,
                  child: const Text('Start Game'),
                ),
                ElevatedButton(
                  onPressed: isFlying && !isCrashed ? _cashOut : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Cash Out'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Bet Amount
            TextField(
              decoration: const InputDecoration(labelText: 'Bet Amount (₹)'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  betAmount = double.tryParse(value) ?? 100.0;
                });
              },
            ),
            const SizedBox(height: 10),
            Text('Potential Win: ₹${potentialWin.toStringAsFixed(2)}'),
            const SizedBox(height: 20),
            // Prediction
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Suggested Cash Out: ${suggestedCashOut.toStringAsFixed(2)}x',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(predictionReason),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // History
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Game ${index + 1}: ${history[index].toStringAsFixed(2)}x'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}