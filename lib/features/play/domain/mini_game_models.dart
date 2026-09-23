import '../../home/domain/pet_models.dart';

enum MiniGameType {
  ticTacToe,
  matchingPairs,
  rockPaperScissors,
  repeatSequence,
  oddOneOut,
}

extension MiniGameTypePersistence on MiniGameType {
  String get persistentId => switch (this) {
    MiniGameType.ticTacToe => 'tic_tac_toe',
    MiniGameType.matchingPairs => 'matching_pairs',
    MiniGameType.rockPaperScissors => 'rock_paper_scissors',
    MiniGameType.repeatSequence => 'repeat_sequence',
    MiniGameType.oddOneOut => 'odd_one_out',
  };
}

class MiniGameReward {
  const MiniGameReward({required this.xp});

  static const int firstCompletionXp = 2;

  final int xp;

  bool get wasAwarded => xp > 0;
}

class MiniGameSessionResult {
  const MiniGameSessionResult({
    required this.outcome,
    required this.title,
    required this.message,
    required this.reward,
  });

  final MiniGameResult outcome;
  final String title;
  final String message;
  final MiniGameReward reward;
}
