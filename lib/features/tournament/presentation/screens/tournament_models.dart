import 'dart:math';
import 'package:flutter/material.dart';
import '../../../members/domain/models/member_item.dart';

// ============================================================
// 복식 대진표 — 모델 & 대진 생성 엔진
// ============================================================

int tournamentAge(MemberItem m) {
  if (m.birth.length < 6) return 0;
  final yy = int.tryParse(m.birth.substring(0, 2)) ?? 0;
  return DateTime.now().year - (yy >= 30 ? 1900 + yy : 2000 + yy);
}

enum RoundType {
  same('동일급수', 'AA↔AA  BB↔BB  CC↔CC  DD↔DD', Color(0xFF4A7FB5)),
  balanced('균형급수', 'AD↔BC  BB↔AC  CC↔BD', Color(0xFF5A9E6B)),
  random('랜덤급수', '급수 무관  나이 차 최소화', Color(0xFF9B6BBB));

  final String label;
  final String desc;
  final Color color;
  const RoundType(this.label, this.desc, this.color);
}

class TournamentTeam {
  final MemberItem? p1;
  final MemberItem? p2;
  const TournamentTeam(this.p1, this.p2);
  bool get isBye => p1 == null || p2 == null;
  double get avgAge {
    final ages = [if (p1 != null) tournamentAge(p1!), if (p2 != null) tournamentAge(p2!)];
    return ages.isEmpty ? 0 : ages.reduce((a, b) => a + b) / ages.length;
  }
}

class TournamentMatch {
  final RoundType roundType;
  final int courtNo;
  final TournamentTeam teamA;
  final TournamentTeam teamB;
  const TournamentMatch({
    required this.roundType,
    required this.courtNo,
    required this.teamA,
    required this.teamB,
  });
}

// ============================================================
// 대진표 생성 엔진
// ============================================================
class TournamentEngine {
  final List<MemberItem> players;
  final List<RoundType> rounds;
  final int courts;
  final int gamesPerPlayer;
  final Random _rng = Random();

  TournamentEngine(this.players, this.rounds, this.courts, this.gamesPerPlayer);

  List<TournamentMatch> generate() {
    final byGrade = <String, List<MemberItem>>{};
    for (final m in players) {
      byGrade.putIfAbsent(m.grade, () => []).add(m);
    }
    byGrade.forEach((_, list) => list.shuffle(_rng));

    final all = <TournamentMatch>[];
    int courtOffset = 0;
    int roundIdx = 0;

    for (int g = 0; g < gamesPerPlayer; g++) {
      final rt = rounds[roundIdx % rounds.length];
      roundIdx++;
      List<TournamentMatch> raw;
      switch (rt) {
        case RoundType.same:     raw = _buildSame(byGrade);
        case RoundType.balanced: raw = _buildBalanced(byGrade);
        case RoundType.random:   raw = _buildRandom();
      }
      for (int i = 0; i < raw.length; i++) {
        final courtNo = (courtOffset + i) % courts + 1;
        all.add(TournamentMatch(
          roundType: raw[i].roundType,
          courtNo: courtNo,
          teamA: raw[i].teamA,
          teamB: raw[i].teamB,
        ));
      }
      courtOffset += raw.length;
      byGrade.forEach((_, list) => list.shuffle(_rng));
    }
    return all;
  }

  List<TournamentMatch> _buildSame(Map<String, List<MemberItem>> byGrade) {
    final matches = <TournamentMatch>[];
    for (final grade in ['A', 'B', 'C', 'D', '초심']) {
      final list = _byAge(byGrade[grade] ?? []);
      final padded = List<MemberItem?>.from(list);
      if (padded.length % 2 != 0) padded.add(null);
      final teams = <TournamentTeam>[];
      for (int i = 0; i + 1 < padded.length; i += 2) {
        teams.add(TournamentTeam(padded[i], padded[i + 1]));
      }
      if (teams.length % 2 != 0) teams.add(TournamentTeam(null, null));
      for (int i = 0; i + 1 < teams.length; i += 2) {
        matches.add(TournamentMatch(roundType: RoundType.same, courtNo: 0,
            teamA: teams[i], teamB: teams[i + 1]));
      }
    }
    return matches;
  }

  List<TournamentMatch> _buildBalanced(Map<String, List<MemberItem>> byGrade) {
    final matches = <TournamentMatch>[];
    final a = _byAge(byGrade['A'] ?? []);
    final b = _byAge(byGrade['B'] ?? []);
    final c = _byAge(byGrade['C'] ?? []);
    final d = _byAge(byGrade['D'] ?? []);

    matches.addAll(_pairTeams(_crossPair(a, d), _crossPair(b, c), RoundType.balanced));
    matches.addAll(_pairTeams(_samePair(b), _crossPair(a, c), RoundType.balanced));
    matches.addAll(_pairTeams(_samePair(c), _crossPair(b, d), RoundType.balanced));
    return matches;
  }

  List<TournamentMatch> _buildRandom() {
    final sorted = _byAge(players);
    final teams = <TournamentTeam>[];
    final usedP = <String>{};
    for (int i = 0; i < sorted.length; i++) {
      if (usedP.contains(sorted[i].id)) continue;
      MemberItem? partner; int bestDiff = 9999;
      for (int j = i + 1; j < sorted.length; j++) {
        if (usedP.contains(sorted[j].id)) continue;
        final diff = (tournamentAge(sorted[i]) - tournamentAge(sorted[j])).abs();
        if (diff < bestDiff) { bestDiff = diff; partner = sorted[j]; }
      }
      if (partner != null) {
        teams.add(TournamentTeam(sorted[i], partner));
        usedP.add(sorted[i].id); usedP.add(partner.id);
      }
    }
    final matches = <TournamentMatch>[];
    final usedT = <int>{};
    for (int i = 0; i < teams.length; i++) {
      if (usedT.contains(i)) continue;
      double best = double.infinity; int bestJ = -1;
      for (int j = i + 1; j < teams.length; j++) {
        if (usedT.contains(j)) continue;
        final diff = (teams[i].avgAge - teams[j].avgAge).abs();
        if (diff < best) { best = diff; bestJ = j; }
      }
      if (bestJ != -1) {
        matches.add(TournamentMatch(roundType: RoundType.random, courtNo: 0,
            teamA: teams[i], teamB: teams[bestJ]));
        usedT.add(i); usedT.add(bestJ);
      }
    }
    return matches;
  }

  List<MemberItem> _byAge(List<MemberItem> list) =>
      List<MemberItem>.from(list)..sort((a, b) => tournamentAge(a) - tournamentAge(b));

  List<TournamentTeam> _crossPair(List<MemberItem> l1, List<MemberItem> l2) {
    final teams = <TournamentTeam>[];
    final used = <String>{};
    for (final p1 in l1) {
      MemberItem? best; int bestDiff = 9999;
      for (final p2 in l2) {
        if (used.contains(p2.id)) continue;
        final diff = (tournamentAge(p1) - tournamentAge(p2)).abs();
        if (diff < bestDiff) { bestDiff = diff; best = p2; }
      }
      if (best != null) { teams.add(TournamentTeam(p1, best)); used.add(best.id); }
    }
    return teams;
  }

  List<TournamentTeam> _samePair(List<MemberItem> list) {
    final sorted = _byAge(list);
    final teams = <TournamentTeam>[];
    for (int i = 0; i + 1 < sorted.length; i += 2) {
      teams.add(TournamentTeam(sorted[i], sorted[i + 1]));
    }
    return teams;
  }

  List<TournamentMatch> _pairTeams(List<TournamentTeam> listA, List<TournamentTeam> listB, RoundType rt) {
    final matches = <TournamentMatch>[];
    final usedB = <int>{};
    for (final tA in listA) {
      double best = double.infinity; int bestIdx = -1;
      for (int j = 0; j < listB.length; j++) {
        if (usedB.contains(j)) continue;
        final diff = (tA.avgAge - listB[j].avgAge).abs();
        if (diff < best) { best = diff; bestIdx = j; }
      }
      if (bestIdx != -1) {
        matches.add(TournamentMatch(roundType: rt, courtNo: 0, teamA: tA, teamB: listB[bestIdx]));
        usedB.add(bestIdx);
      }
    }
    return matches;
  }
}
