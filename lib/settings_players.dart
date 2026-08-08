// Flutter basics
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

// Database Models
import 'package:darts_101/database/tbl_player.dart';

// Backend Logic
import 'package:darts_101/global_be.dart';
import 'package:darts_101/settings_players_be.dart';

// UI Screens
// import 'package:darts_101/manage_players.dart';

class SettingsPlayers extends StatelessWidget {
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

  // Fonction de navigation when a button is pressed
  /* void _addPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // The add_player.dart page will be created and shown
        builder: (context) => ModifyAddPlayerForm(
          enuFormMode: FormMode.formAdd,          
        ),
      ),
    );
  } */

  // Fonction de navigation when a button is pressed
  /* void _onTileTapped() {    
    Navigator.push(
      context,
      MaterialPageRoute(
        // The add_player.dart page will be created and shown
        builder: (context) => ModifyAddPlayerForm(
          enuFormMode: FormMode.formModify,
          modifyPlayer: player,         
        ),
      ),
    );
  } */

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);

    // 1. Access the Hive box opened during initialization
    final playersBox = Hive.box<TblPlayer>('playersBox');
    final ImageCardFrameConfig imageCardFrameConfig = getCarouselCardFrameImageConfig();

    return Scaffold(
      //pour le background color en bas du titre et pour le reste de la page
      backgroundColor: tileBackgroundColor,
      appBar: AppBar(        
        foregroundColor: Colors.white,
        backgroundColor: tileColor,
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
              tileDescription,              
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),        
      ),

      body: Column(
        children: [
          // 1. TOP SEGMENTED TOGGLE BAR (Reserved for sub-filters if needed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            color: Colors.grey.shade900,
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
                    final players = box.values.toList();

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
                        // final player = players[index];
                        // _onPlayerTapped(context, player);
                      },
                      children: players
                          .map((player) => _buildPlayerCard(context, player, tileColor))
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
    Color cardColor,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}