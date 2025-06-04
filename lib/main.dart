import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants/app_constants.dart';
import 'widgets/grid_cell_widget.dart';
import 'models/game_board.dart';
import 'screens/game_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'utils/game_utils.dart';
import 'leaderboard_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ModuloApp());
}

class ModuloApp extends StatelessWidget {
  const ModuloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modulo',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        // Add other supported locales here
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return const LoginScreen();
        }
        return const ModuloGame();
      },
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.photoURL != null)
              CircleAvatar(
                backgroundImage: NetworkImage(user!.photoURL!),
                radius: 40,
              ),
            const SizedBox(height: 10),
            Text('Name: ${user?.displayName ?? "N/A"}'),
            Text('Email: ${user?.email ?? "N/A"}'),
            Text('UID: ${user?.uid ?? "N/A"}'),
            ElevatedButton(
              child: const Text('Sign Out'),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            )
          ],
        ),
      ),
    );
  }
}

class ModuloGame extends StatefulWidget {
  const ModuloGame({super.key});

  @override
  _ModuloGameState createState() => _ModuloGameState();
}

class _ModuloGameState extends State<ModuloGame> {
  late GameBoard gameBoard;
  int difficultyLevel = 1;
  int highScore = 0;

  int get gridSize => 4 + ((difficultyLevel - 1) ~/ 10).clamp(0, 6);

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _initializeGameBoard();
  }

  Future<void> _loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  void _initializeGameBoard() {
    setState(() {
      gameBoard = GameBoard(
        rows: gridSize,
        cols: gridSize,
        maxValue: (difficultyLevel * 1000).clamp(1, 100000),
      );
    });
  }

  void _move(int row, int col, int dRow, int dCol) {
    setState(() {
      if (gameBoard.move(row, col, dRow, dCol)) {
        if (gameBoard.score > highScore) {
          highScore = gameBoard.score;
          _saveHighScore();
        }
        _checkWinLose();
      }
    });
  }

  void _checkWinLose() {
    if (gameBoard.isBoardClear()) {
      _showEndDialog(AppStrings.youWin, AppLocalizations.of(context).winMessage(gameBoard.score), true);
      return;
    }
    if (!gameBoard.hasMoves()) {
      _showEndDialog(AppStrings.gameOver, AppLocalizations.of(context).gameOverMessage(gameBoard.score), true);
    }
  }

  void _showEndDialog(String title, String message, bool showLeaderboardOption) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        TextEditingController nameController = TextEditingController();

        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              if (showLeaderboardOption) ...[
                SizedBox(height: 20),
                Text(AppStrings.enterName, style: const TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: AppStrings.yourName,
                  ),
                ),
              ]
            ],
          ),
          actions: [
            if (showLeaderboardOption)
              TextButton(
                onPressed: () async {
                  final playerName = nameController.text.trim();
                  if (playerName.isNotEmpty) {
                    await LeaderboardService.submitScore(context, playerName, score);
                    Navigator.of(context).pop();
                    _showLeaderboardDialog();
                  }
                },
                child: const Text(AppStrings.submitScore),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeGameBoard();
              },
              child: const Text(AppStrings.playAgain),
            )
          ],
        );
      },
    );
  }

  void _showLeaderboardDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(AppStrings.globalLeaderboard),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: LeaderboardService.getTopScores(10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text(AppStrings.noScoresYet));
                }
                final scores = snapshot.data!;
                return ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (_, index) {
                    final item = scores[index];
                    return ListTile(
                      leading: Text('#${index + 1}'),
                      title: Text(item['name']),
                      trailing: Text(item['score'].toString()),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.close),
            )
          ],
        );
      },
    );
  }

  // Widget _buildGrid() {
  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: List.generate(gameBoard.rows, (row) {
  //       return Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: List.generate(gameBoard.cols, (col) {
  //           return GestureDetector(
  //             onVerticalDragEnd: (details) {
  //               if (details.primaryVelocity != null) {
  //                 if (details.primaryVelocity! < 0) {
  //                   _move(row, col, -1, 0); // Up
  //                 } else if (details.primaryVelocity! > 0) {
  //                   _move(row, col, 1, 0); // Down
  //                 }
  //               }
  //             },
  //             onHorizontalDragEnd: (details) {
  //               if (details.primaryVelocity != null) {
  //                 if (details.primaryVelocity! < 0) {
  //                   _move(row, col, 0, -1); // Left
  //                 } else if (details.primaryVelocity! > 0) {
  //                   _move(row, col, 0, 1); // Right
  //                 }
  //               }
  //             },
  //             child: GridCellWidget(
  //               value: gameBoard.grid[row][col],
  //               isSelected: false,
  //               onTap: () {},
  //             ),
  //           );
  //        }),
  //       );
  //     }),
  //   );
  // }

  Widget _buildDifficultySlider() {
    return Column(
      children: [
        Text(
          '${AppStrings.difficultyLevel} $difficultyLevel',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: difficultyLevel.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          label: difficultyLevel.toString(),
          onChanged: (double value) {
            setState(() {
              difficultyLevel = value.toInt();
              _initializeGameBoard();
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: _showLeaderboardDialog,
            tooltip: AppStrings.showLeaderboard,
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDifficultySlider(),
          const SizedBox(height: 20),
          Text('${AppLocalizations.of(context).score} ${gameBoard.score} ${AppLocalizations.of(context).highScore} $highScore', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          Center(child: GridCellWidget()),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _initializeGameBoard,
            child: const Text(AppStrings.restart),
          ),
        ],
      ),
    );
  }
}

// Remove the duplicate LoginScreen class here!
// Remove the duplicate GridCellWidget class here if you have it in a separate file.
