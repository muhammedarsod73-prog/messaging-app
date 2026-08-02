import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class PasscodeScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const PasscodeScreen({Key? key, required this.onUnlocked}) : super(key: key);

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  String _enteredPin = '';
  bool _isError = false;

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  void _verifyPin() {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    if (_enteredPin == theme.passcode) {
      widget.onUnlocked();
    } else {
      setState(() {
        _isError = true;
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.tealHeader,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock_rounded, size: 56, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'DuoChat Privacy Lock',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isError ? 'Incorrect PIN. Try again.' : 'Enter 4-Digit Passcode',
              style: TextStyle(
                fontSize: 14,
                color: _isError ? Colors.redAccent : Colors.white70,
              ),
            ),
            const SizedBox(height: 30),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppTheme.whatsappGreen : Colors.white24,
                    border: Border.all(color: Colors.white54),
                  ),
                );
              }),
            ),

            const Spacer(),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', 'DEL']
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row.map((btn) {
                        if (btn.isEmpty) {
                          return const SizedBox(width: 70, height: 70);
                        }
                        return InkWell(
                          onTap: () {
                            if (btn == 'DEL') {
                              _onDelete();
                            } else {
                              _onKeyPress(btn);
                            }
                          },
                          borderRadius: BorderRadius.circular(35),
                          child: Container(
                            width: 70,
                            height: 70,
                            alignment: Alignment.center,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                            ),
                            child: btn == 'DEL'
                                ? const Icon(Icons.backspace_outlined, color: Colors.white)
                                : Text(
                                    btn,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
