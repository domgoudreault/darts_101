// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/settings_players_be.dart';

// UI Screens
import 'package:darts_101/modify_add_player.dart';

class SettingsPlayers extends StatefulWidget {
  // Define variables to hold the data passed from the previous screen
  final String tileType;
  final Color tileColor;
  final Color tileBackgroundColor;
  final String tileDescription;

  const SettingsPlayers({
    super.key,
    required this.tileType,
    required this.tileColor,
    required this.tileBackgroundColor,
    required this.tileDescription,
  });

  @override
  State<SettingsPlayers> createState() => _SettingsPlayersState();
}

class _SettingsPlayersState extends State<SettingsPlayers> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fonctions de navigation when a button is pressed
  void _addPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // The add_player.dart page will be created and shown
        builder: (context) => ModifyAddPlayerForm(
          enuFormMode: FormMode.formAdd,
          tileColor: widget.tileColor,
          tileBackgroundColor: widget.tileBackgroundColor,
        ),
      ),
    );
  }

  void _onPlayerTapped(BuildContext context, TblPlayer player) {    
    Navigator.push(
      context,
      MaterialPageRoute(
        // The add_player.dart page will be created and shown
        builder: (context) => ModifyAddPlayerForm(
          enuFormMode: FormMode.formModify,
          modifyPlayer: player,
          tileColor: widget.tileColor,
          tileBackgroundColor: widget.tileBackgroundColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);

    // 1. Access the Hive box opened during initialization
    final playersBox = Hive.box<TblPlayer>('playersBox');
    final ImageCardFrameConfig imageCardFrameConfig = getCarouselCardFrameImageConfig();

    return Scaffold(
      //pour le background color en bas du titre et pour le reste de la page
      backgroundColor: widget.tileBackgroundColor,
      appBar: AppBar(        
        foregroundColor: Colors.white,
        backgroundColor: widget.tileColor,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 48.0,
                height: 48.0,
                child: Image.asset(
                  'assets/png/logos/darts_101_logo_48x48.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Text(
              widget.tileDescription,              
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Add New Player',
            onPressed: () => _addPlayer(context),
            icon: SizedBox(
              width: 48.0,
              height: 48.0,
              child: Image.asset(
                'assets/png/ui_buttons/player_team_add_48x48.png', // Adjust path if needed
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
        ],
      ),

      body: Column(
        children: [
          // 1. TOP SEGMENTED TOGGLE BAR (Reserved for sub-filters if needed)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: imageCardFrameConfig.renderHeight * 0.06,
              vertical: imageCardFrameConfig.renderHeight * 0.02,
            ),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: imageCardFrameConfig.renderHeight * 0.12,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: imageCardFrameConfig.renderHeight * 0.055,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search player name or nickname...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: imageCardFrameConfig.renderHeight * 0.055,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.amber,
                          size: imageCardFrameConfig.renderHeight * 0.09,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.only(
                                right: imageCardFrameConfig.renderHeight * 0.025, // Pulls the 'X' inward on larger cards
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.white54,
                                  size: imageCardFrameConfig.renderHeight * 0.065,
                                ),
                                onPressed: () => _searchController.clear(),
                              ),
                            )
                          : null,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: imageCardFrameConfig.renderHeight * 0.045,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(imageCardFrameConfig.renderHeight * 0.03),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(imageCardFrameConfig.renderHeight * 0.03),
                          borderSide: BorderSide(
                            color: Colors.amber,
                            width: (imageCardFrameConfig.renderHeight * 0.008).clamp(1.5, 4.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. LIVE PLAYER CAROUSEL DISPLAY AREA
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: AppDisplay.carouselTileSize,
                child: ValueListenableBuilder<Box<TblPlayer>>(
                  valueListenable: playersBox.listenable(),
                  builder: (context, box, _) {
                    final allPlayers = box.values.toList();

                    // Filter by First Name, Last Name, or Nickname
                    final players = _searchQuery.isEmpty
                        ? allPlayers
                        : allPlayers.where((player) {
                            final firstName = player.fldFirstName.toLowerCase();
                            final lastName = player.fldLastName.toLowerCase();
                            final nickName = player.fldNickName.toLowerCase();

                            return firstName.contains(_searchQuery) ||
                                lastName.contains(_searchQuery) ||
                                nickName.contains(_searchQuery);
                          }).toList();

                    if (players.isEmpty) {
                      return const Center(
                        child: Text(
                          'No players found.',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      );
                    }

                    return CarouselView(
                      itemExtent: imageCardFrameConfig.renderWidth,
                      shrinkExtent: 80,
                      backgroundColor: Colors.transparent,
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      onTap: (int index) {
                        final player = players[index];
                        _onPlayerTapped(context, player);
                      },
                      children: players
                          .map((player) => _buildPlayerCard(context, player))
                          .toList(),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(
    BuildContext context,
    TblPlayer player,
  ) {
    final ImageCardFrameConfig imageCardFrameConfig = getCarouselCardFrameImageConfig();

    return Center(
      child: AspectRatio(
        aspectRatio: imageCardFrameConfig.renderWidth / imageCardFrameConfig.renderHeight,
        child: FittedBox(
          fit: BoxFit.contain, // Forces height and width to scale down together proportionally
          child: SizedBox(
            width: imageCardFrameConfig.renderWidth,
            height: imageCardFrameConfig.renderHeight,
            child: Stack(
              children: [
                // 1. PNG Frame Background
                Positioned.fill(
                  child: Image.asset(
                    imageCardFrameConfig.assetPathBackground,
                    fit: BoxFit.fill,
                  ),
                ),

                // 2. Avatar Layer
                Positioned.fill(
                  child: Image.asset(
                    getCarouselPlayerImageConfig(player.fldAvatarCode).assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_circle,
                      size: 64,
                      color: Colors.white38,
                    ),
                  ),
                ),

                // 3. PNG Frame Overlay
                Positioned.fill(
                  child: Image.asset(
                    imageCardFrameConfig.assetPathFrame,
                    fit: BoxFit.fill,
                  ),
                ),
                
                // 4. Player Data Text Overlay Layer (On top of white card area)
                Positioned(
                  top: imageCardFrameConfig.renderHeight * 0.52,
                  left: imageCardFrameConfig.renderHeight * 0.08,
                  right: imageCardFrameConfig.renderHeight * 0.08,
                  bottom: imageCardFrameConfig.renderHeight * 0.06,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Gap 1: Picture bottom -> First Name
                      SizedBox(height: imageCardFrameConfig.renderHeight * 0.015),
                      
                      // First Name
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          player.fldFirstName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF111111),
                            fontSize: imageCardFrameConfig.renderHeight * 0.035,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Gap 2: First Name -> Last Name
                      SizedBox(height: imageCardFrameConfig.renderHeight * 0.010),

                      // Last Name
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          player.fldLastName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF111111),
                            fontSize: imageCardFrameConfig.renderHeight * 0.048,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Gap 3: Last Name -> Divider
                      SizedBox(height: imageCardFrameConfig.renderHeight * 0.024),

                      // Divider Accent
                      Container(
                        height: (imageCardFrameConfig.renderHeight * 0.009),
                        width: imageCardFrameConfig.renderHeight * 0.50,
                        color: widget.tileColor,
                      ),
                      
                      // Gap 4: Divider -> Nickname
                      SizedBox(height: imageCardFrameConfig.renderHeight * 0.022),

                      // Elliptic Arcade Badge around Nickname
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: imageCardFrameConfig.renderHeight * 0.035,
                          vertical: imageCardFrameConfig.renderHeight * 0.006,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.shade100,
                          borderRadius: BorderRadius.circular(
                            imageCardFrameConfig.renderHeight * 0.04,
                          ),
                          border: Border.all(
                            color: Colors.purpleAccent.shade700,
                            width: imageCardFrameConfig.renderHeight * 0.006,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '« ${player.fldNickName} »'.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: imageCardFrameConfig.renderHeight * 0.042,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}