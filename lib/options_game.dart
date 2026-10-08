// Flutter basics
import 'package:darts_101/helpers_ui.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

// Database Models
import 'package:darts_101/database/enum_game_type.dart';
import 'package:darts_101/database/tbl_game_options.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';

class GameOptionsDialog extends StatefulWidget {
  final GlobalGameType enuGameType;
  
  const GameOptionsDialog({super.key, required this.enuGameType});

  @override
  State<GameOptionsDialog> createState() => _GameOptionsDialogState();
}

class _GameOptionsDialogState extends State<GameOptionsDialog> {
  late TblGameOptions _options;
  late int _startingScore;
  late int _nbrRounds;
  late int _nbrLives;
  late bool _startEndBull;
  late bool _startEndDoubleBull;
  late bool _upDownBull;
  late bool _midDoubleBull;
  late bool _noSkipWhenBull;

  @override
  void initState() {
    super.initState();
    final optionsBox = Hive.box<TblGameOptions>('gameOptionsBox');
    _options = optionsBox.values.firstWhere(
      (opt) => opt.fldGameType == widget.enuGameType,
    );
    
    // Initialize local state from database record
    _startingScore = _options.fldStartingScore;
    _nbrRounds = _options.fldNbrRounds;
    _nbrLives = _options.fldNbrLives;
    _startEndBull = _options.fldStartEndBull;
    _startEndDoubleBull = _options.fldStartEndDoubleBull;
    _upDownBull = _options.fldUpDownBull;
    _midDoubleBull = _options.fldMidDoubleBull;
    _noSkipWhenBull = _options.fldNoSkipWhenBull;
  }

  Future<void> _saveOptions() async {
    _options.fldStartingScore = _startingScore;
    _options.fldNbrRounds = _nbrRounds;
    _options.fldNbrLives = _nbrLives;
    _options.fldStartEndBull = _startEndBull;
    _options.fldStartEndDoubleBull = _startEndDoubleBull;
    _options.fldUpDownBull = _upDownBull;
    _options.fldMidDoubleBull = _midDoubleBull;
    _options.fldNoSkipWhenBull = _noSkipWhenBull;
    
    await _options.save(); // Save changes to Hive
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final safeHeight = GlobalAppDisplay.safeHeight;
    final safeWidth = GlobalAppDisplay.safeWidth;

    return AlertDialog(
      backgroundColor: widget.enuGameType.tileColor, // Colors.grey.shade900,
      
      title: Center(
        child: Text(
          'Options',
          style: gBuildArcadeTextStyle(safeHeight * 0.025, gFontWeight: FontWeight.bold),
        ),
      ),
      content: SizedBox(
        width: safeWidth * 0.35,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.enuGameType.tileDisplayName,
              style: gBuildArcadeTextStyle(safeHeight * 0.025, gFontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: safeHeight * 0.02),
            
            // Starting Score Option (if visible)
            if (_options.fldShowOptStartingScore)
              Padding(
                padding: EdgeInsets.symmetric(vertical: safeHeight * 0.01),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Starting Score', 
                      style: TextStyle(
                        fontSize: safeHeight * 0.025, 
                        fontWeight: FontWeight.w500, 
                        color: Colors.white
                      ),
                    ),
                    Row(
                      children: [
                        _buildPillButton(safeHeight, 
                          Icon(
                            Icons.remove,
                            color: Color.fromARGB(255, 207, 20, 17),
                            size: safeHeight * 0.025,
                          ),
                          () => setState(() => _startingScore = (_startingScore - 25).clamp(25, 200))
                        ),

                        SizedBox(width: safeHeight * 0.01),
                        
                        Text(
                          '$_startingScore', 
                          style: TextStyle(
                            fontSize: safeHeight * 0.025,
                            fontWeight: FontWeight.w500, 
                            color: Colors.white
                          ),
                        ),

                        SizedBox(width: safeHeight * 0.01),

                        _buildPillButton(safeHeight, 
                          Icon(
                            Icons.add,
                            color: Color.fromARGB(255, 207, 20, 17),
                            size: safeHeight * 0.025,
                          ),
                          () => setState(() => _startingScore = (_startingScore + 25).clamp(25, 200))
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Number of Rounds Option (if visible)
            if (_options.fldShowOptNbrRounds)
              Padding(
                padding: EdgeInsets.symmetric(vertical: safeHeight * 0.01),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Number of Rounds', 
                      style: TextStyle(
                        fontSize: safeHeight * 0.025, 
                        fontWeight: FontWeight.w500, 
                        color: Colors.white
                      ),
                    ),
                    Row(
                      children: [
                        _buildPillButton(safeHeight, 
                          Icon(
                            Icons.remove,
                            color: Color.fromARGB(255, 207, 20, 17),
                            size: safeHeight * 0.025,
                          ),
                          () => setState(() => _nbrRounds = (_nbrRounds - 1).clamp(3, 7))
                        ),

                        SizedBox(width: safeHeight * 0.01),
                        
                        Text(
                          '$_nbrRounds', 
                          style: TextStyle(
                            fontSize: safeHeight * 0.025,
                            fontWeight: FontWeight.w500, 
                            color: Colors.white
                          ),
                        ),

                        SizedBox(width: safeHeight * 0.01),

                        _buildPillButton(safeHeight, 
                          Icon(
                            Icons.add,
                            color: Color.fromARGB(255, 207, 20, 17),
                            size: safeHeight * 0.025,
                          ),
                          () => setState(() => _nbrRounds = (_nbrRounds + 1).clamp(3, 7))
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Number of Lives Option (if visible)
            if (_options.fldShowOptNbrLives)
              Padding(
                padding: EdgeInsets.symmetric(vertical: safeHeight * 0.01),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Number of Lives', 
                      style: TextStyle(
                        fontSize: safeHeight * 0.025, 
                        fontWeight: FontWeight.w500, 
                        color: Colors.white
                      ),
                    ),
                    Row(
                      children: [
                        _buildPillButton(safeHeight, 
                          Icon(
                            Icons.remove,
                            color: Color.fromARGB(255, 207, 20, 17),
                            size: safeHeight * 0.025,
                          ),
                          () => setState(() => _nbrLives = (_nbrLives - 1).clamp(3, 9))
                        ),

                        SizedBox(width: safeHeight * 0.01),
                        
                        Text(
                          '$_nbrLives', 
                          style: TextStyle(
                            fontSize: safeHeight * 0.025,
                            fontWeight: FontWeight.w500, 
                            color: Colors.white
                          ),
                        ),

                        SizedBox(width: safeHeight * 0.01),

                        _buildPillButton(safeHeight, 
                          Icon(
                            Icons.add,
                            color: Color.fromARGB(255, 207, 20, 17),
                            size: safeHeight * 0.025,
                          ),
                          () => setState(() => _nbrLives = (_nbrLives + 1).clamp(3, 9))
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            // Start/End Bull Option (if visible)
            if (_options.fldShowOptStartEndBull)
              _buildSwitchOption(
                label: 'Start and End the game with one Bullseye',
                value: _startEndBull,
                onChanged: (val) => setState(() => _startEndBull = val),
                safeHeight: safeHeight
              ),

            // Start/End Double Bull Option (if visible)
            if (_options.fldShowOptStartEndDoubleBull)
              _buildSwitchOption(
                label: 'Start and End the game with two Bullseyes',
                value: _startEndDoubleBull,
                onChanged: (val) => setState(() => _startEndDoubleBull = val),
                safeHeight: safeHeight
              ),

            // Up/Down Bull Option (if visible)
            if (_options.fldShowOptUpDownBull)
              _buildSwitchOption(
                label: 'Game goes Up with one Middle Bullseye and Down',
                value: _upDownBull,
                onChanged: (val) {
                  setState(() {
                    _upDownBull = val;
                    if (!_upDownBull) {
                      _midDoubleBull = false; // Force false and disable when upDownBull is false
                    }
                  });
                },
                safeHeight: safeHeight
              ),

            // Mid Double Bull Option (if visible)
            if (_options.fldShowOptMidDoubleBull)
              Opacity(
                opacity: _upDownBull ? 1.0 : 0.4, // Visual cue that it's disabled
                child: AbsorbPointer(
                  absorbing: !_upDownBull, // Blocks touches when upDownBull is false
                  child: _buildSwitchOption(
                    label: 'Middle with two Bullseyes',
                    value: _midDoubleBull,
                    onChanged: (val) => setState(() => _midDoubleBull = val),
                    safeHeight: safeHeight,
                  ),
                ),
              ),

            // No Skip When Bull Option (if visible)
            if (_options.fldShowOptNoSkipWhenBull)
              _buildSwitchOption(
                label: 'No Skip on Bullseye',
                value: _noSkipWhenBull,
                onChanged: (val) => setState(() => _noSkipWhenBull = val),
                safeHeight: safeHeight,
                hasInfo: true,
              ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 207, 20, 17)),
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel', 
            style: TextStyle(
              fontSize: safeHeight * 0.025, 
              fontWeight: FontWeight.w500,
              color: Colors.white
            ),
          ),
        ),
        
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          onPressed: _saveOptions,
          child: Text(
            'Save', 
            style: TextStyle(
              fontSize: safeHeight * 0.025, 
              fontWeight: FontWeight.w500,
              color: Colors.black
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillButton(double safeHeight, Icon pillIcon, VoidCallback onTap){
    // Pill container around the "+" button
    return SizedBox(
      width: safeHeight * 0.03,
      height: safeHeight * 0.04,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(
            safeHeight * 0.012,
          ),
          border: Border.all(
            color: Colors.black,
            width: safeHeight * 0.0015,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(safeHeight * 0.016),
            onTap: onTap,
            child: Center(
              child: pillIcon,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOption({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double safeHeight,
    bool hasInfo = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: safeHeight * 0.005),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            hasInfo ? '$label ' : label,
            style: TextStyle(
              fontSize: safeHeight * 0.02,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          if (hasInfo) ...[
            _buildPillButton(
              safeHeight, 
              Icon(
                Icons.question_mark, // or Icons.info_outline
                color: Color.fromARGB(255, 207, 20, 17),
                size: safeHeight * 0.025,
              ),
              () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: widget.enuGameType.tileColor,
                    title: Text(
                      'No Skip on Bullseye',
                      style: gBuildArcadeTextStyle(safeHeight * 0.025, gFontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'No Skipping when arriving to Bullseyes or after hitting them',
                      style: TextStyle(fontSize: safeHeight * 0.02, color: Colors.white),
                    ),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it', style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(),
          ],

          Switch(
            value: value,
            activeThumbColor: Colors.amber,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}